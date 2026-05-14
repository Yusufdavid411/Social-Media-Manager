import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { BullModule } from '@nestjs/bullmq';
import { ScheduleModule } from '@nestjs/schedule';
import { AiModule } from './modules/ai/ai.module';
import { AuditModule } from './modules/audit/audit.module';
import { AuthModule } from './modules/auth/auth.module';
import { BillingModule } from './modules/billing/billing.module';
import { CalendarModule } from './modules/calendar/calendar.module';
import { CleanupModule } from './modules/cleanup/cleanup.module';
import { DatabaseModule } from './modules/database/database.module';
import { MediaModule } from './modules/media/media.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { PostComposerModule } from './modules/post-composer/post-composer.module';
import { PublishingModule } from './modules/publishing/publishing.module';
import { SchedulingModule } from './modules/scheduling/scheduling.module';
import { SocialAccountsModule } from './modules/social-accounts/social-accounts.module';
import { UsersModule } from './modules/users/users.module';
import { WorkspacesModule } from './modules/workspaces/workspaces.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    BullModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        connection: {
          host: config.get<string>('REDIS_HOST') ?? 'localhost',
          port: config.get<number>('REDIS_PORT') ?? 6379,
        },
      }),
    }),
    ScheduleModule.forRoot(),
    DatabaseModule,
    AuditModule,
    AuthModule,
    UsersModule,
    WorkspacesModule,
    SocialAccountsModule,
    MediaModule,
    PostComposerModule,
    SchedulingModule,
    PublishingModule,
    CalendarModule,
    BillingModule,
    AiModule,
    CleanupModule,
    NotificationsModule,
  ],
})
export class AppModule {}
