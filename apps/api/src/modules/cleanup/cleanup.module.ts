import { BullModule } from '@nestjs/bullmq';
import { Module } from '@nestjs/common';
import { CLEANUP_QUEUE } from '../../common/constants/queues';
import { AuditModule } from '../audit/audit.module';
import { MediaModule } from '../media/media.module';
import { CleanupProcessor } from './cleanup.processor';
import { CleanupService } from './cleanup.service';

@Module({
  imports: [
    BullModule.registerQueue({ name: CLEANUP_QUEUE }),
    AuditModule,
    MediaModule,
  ],
  providers: [CleanupService, CleanupProcessor],
  exports: [CleanupService],
})
export class CleanupModule {}
