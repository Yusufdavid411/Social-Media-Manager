import { Injectable, Logger } from '@nestjs/common';

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  async notifyUser(userId: string, message: string) {
    this.logger.log(`Notification placeholder for ${userId}: ${message}`);
  }
}
