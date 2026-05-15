import { Controller, Get } from '@nestjs/common';

@Controller('health')
export class HealthController {
  @Get()
  check() {
    return {
      status: 'ok',
      service: 'social-media-manager-api',
      timestamp: new Date().toISOString(),
    };
  }
}
