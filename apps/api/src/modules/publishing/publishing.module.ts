import { BullModule } from '@nestjs/bullmq';
import { Module } from '@nestjs/common';
import { PUBLISHING_QUEUE } from '../../common/constants/queues';
import { CalendarModule } from '../calendar/calendar.module';
import { PublishingProcessor } from './publishing.processor';
import { PublishingService } from './publishing.service';

@Module({
  imports: [
    BullModule.registerQueue({ name: PUBLISHING_QUEUE }),
    CalendarModule,
  ],
  providers: [PublishingService, PublishingProcessor],
  exports: [PublishingService],
})
export class PublishingModule {}
