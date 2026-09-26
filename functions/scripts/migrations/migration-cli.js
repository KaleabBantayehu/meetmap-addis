import { appendFile, mkdir, readFile, rename, writeFile } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

import {
  migrationBatchSize,
  productionProjectId,
} from '../../src/production-migrations.js';

export const checkpointSchemaVersion = 1;

function option(name) {
  const prefix = `--${name}=`;
  return process.argv.slice(2).find((value) => value.startsWith(prefix))
    ?.slice(prefix.length).trim();
}

function flag(name) {
  return process.argv.slice(2).includes(`--${name}`);
}

async function readCheckpoint(path) {
  if (!path) return {};
  try {
    return JSON.parse(await readFile(resolve(path), 'utf8'));
  } catch (error) {
    if (error.code === 'ENOENT') return {};
    throw error;
  }
}

export function validateCheckpoint(checkpoint, {
  migrationName,
  projectId,
  mode,
}) {
  if (checkpoint == null || Array.isArray(checkpoint) || typeof checkpoint !== 'object') {
    throw new Error('Checkpoint has an invalid or incompatible schema');
  }
  if (Object.keys(checkpoint).length === 0) return;
  if (
    checkpoint.version !== checkpointSchemaVersion ||
    typeof checkpoint.migration !== 'string' ||
    typeof checkpoint.projectId !== 'string' ||
    (checkpoint.mode !== 'dry-run' && checkpoint.mode !== 'write')
  ) {
    throw new Error('Checkpoint has an invalid or incompatible schema');
  }
  if (checkpoint.migration !== migrationName) {
    throw new Error(`Checkpoint belongs to migration ${checkpoint.migration}`);
  }
  if (checkpoint.projectId !== projectId) {
    throw new Error(`Checkpoint belongs to project ${checkpoint.projectId}`);
  }
  if (checkpoint.mode !== mode) {
    throw new Error(
      `Checkpoint mode ${checkpoint.mode} cannot be used for ${mode} execution`,
    );
  }
}

async function writeCheckpoint(path, value) {
  if (!path) return;
  const target = resolve(path);
  await mkdir(dirname(target), { recursive: true });
  const temporary = `${target}.tmp`;
  await writeFile(temporary, `${JSON.stringify(value, null, 2)}\n`);
  await rename(temporary, target);
}

function errorCount(value) {
  if (value == null || typeof value !== 'object') return 0;
  let total = value.counts?.errors ?? 0;
  for (const [key, child] of Object.entries(value)) {
    if (key !== 'counts') total += errorCount(child);
  }
  return total;
}

export async function runMigrationCli({ migrationName, execute }) {
  const projectId = option('project');
  if (!projectId) throw new Error('Provide --project=<project-id>');
  const write = flag('write');
  const confirmProduction = flag('confirm-production');
  if (write && projectId === productionProjectId && !confirmProduction) {
    throw new Error('Production writes require --write --confirm-production');
  }
  const parsedBatchSize = Number(option('batch-size') ?? migrationBatchSize);
  if (!Number.isInteger(parsedBatchSize)) throw new Error('Invalid --batch-size');

  const checkpointPath = option('checkpoint');
  const manifestPath = option('manifest');
  if (write && (!checkpointPath || !manifestPath)) {
    throw new Error('Write mode requires both --checkpoint=<path> and --manifest=<path>');
  }
  const checkpoint = await readCheckpoint(checkpointPath);
  const mode = write ? 'write' : 'dry-run';
  validateCheckpoint(checkpoint, {
    migrationName,
    projectId,
    mode,
  });
  const executionId = `${migrationName}-${new Date().toISOString()}`;
  if (write && projectId === productionProjectId) {
    console.error(`WARNING: authorized production write for ${migrationName} on ${projectId}`);
  }

  const app = initializeApp(
    { credential: applicationDefault(), projectId },
    executionId,
  );
  const db = getFirestore(app);
  const header = {
    recordType: 'execution',
    migration: migrationName,
    version: 1,
    executionId,
    projectId,
    mode,
    startedAt: new Date().toISOString(),
  };
  if (manifestPath) {
    const target = resolve(manifestPath);
    await mkdir(dirname(target), { recursive: true });
    await appendFile(target, `${JSON.stringify(header)}\n`);
  }

  const record = async (value) => {
    if (!manifestPath) return;
    await appendFile(resolve(manifestPath), `${JSON.stringify({
      ...value,
      migration: migrationName,
      executionId,
      projectId,
      recordedAt: new Date().toISOString(),
    })}\n`);
  };
  const onCheckpoint = async (progress) => writeCheckpoint(checkpointPath, {
    migration: migrationName,
    version: checkpointSchemaVersion,
    projectId,
    mode,
    updatedAt: new Date().toISOString(),
    ...checkpoint,
    ...progress,
  });

  const result = await execute({
    db,
    projectId,
    write,
    confirmProduction,
    batchSize: parsedBatchSize,
    checkpoint,
    record,
    onCheckpoint,
  });
  const errors = errorCount(result);
  await record({
    recordType: 'completion',
    status: errors === 0 ? 'completed' : 'completed-with-errors',
    errors,
  });
  console.log(JSON.stringify({
    ...result,
    mode,
    status: errors === 0 ? 'completed' : 'completed-with-errors',
  }));
  if (errors > 0) process.exitCode = 2;
}
