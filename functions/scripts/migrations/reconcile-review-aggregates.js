import { runReviewAggregateReconciliation } from '../../src/production-migrations.js';
import { runMigrationCli } from './migration-cli.js';

await runMigrationCli({
  migrationName: 'review-aggregates-v1',
  execute: ({ checkpoint, ...options }) => runReviewAggregateReconciliation({
    ...options,
    startAfterId: checkpoint.lastProcessedId,
  }),
});
