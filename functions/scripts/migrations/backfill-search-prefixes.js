import { runSearchPrefixBackfill } from '../../src/production-migrations.js';
import { runMigrationCli } from './migration-cli.js';

await runMigrationCli({
  migrationName: 'search-prefixes-v1',
  execute: ({ checkpoint, ...options }) => runSearchPrefixBackfill({
    ...options,
    startAfterId: checkpoint.lastProcessedId,
  }),
});
