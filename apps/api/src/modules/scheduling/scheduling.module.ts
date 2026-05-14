import { BullModule } from '@nestjs/bullmq';
import { Module } from '@nestjs/common';
import { PUBLISHING_QUEUE } from '../../common/constants/queues';
import { CalendarModule } from '../calendar/calendar.module';
import { SchedulingService } from './scheduling.service';

@Module({
  imports: [
    BullModule.registerQueue({ name: PUBLISHING_QUEUE }),
    CalendarModule,
  ],
  providers: [SchedulingService],
  exports: [SchedulingService],
})
export class SchedulingModule {}
