import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Job } from 'bullmq';
import { CLEANUP_QUEUE } from '../../common/constants/queues';
import { CleanupService } from './cleanup.service';

@Processor(CLEANUP_QUEUE)
export class CleanupProcessor extends WorkerHost {
  constructor(private readonly cleanup: CleanupService) {
    super();
  }

  async process(_job: Job) {
    await this.cleanup.runRetentionCleanup();
  }
}
