import { runLifecycleBackfill } from '../../src/production-migrations.js';
import { runMigrationCli } from './migration-cli.js';

await runMigrationCli({
  migrationName: 'lifecycle-status-v1',
  execute: ({ checkpoint, ...options }) => {
    const collections = { ...(checkpoint.collections ?? {}) };
    return runLifecycleBackfill({
      ...options,
      checkpoints: collections,
      onCheckpoint: async (progress) => {
        collections[progress.collectionPath] = progress.lastProcessedId;
        await options.onCheckpoint({
          collections: { ...collections },
          counts: progress.counts,
        });
      },
    });
  },
});
