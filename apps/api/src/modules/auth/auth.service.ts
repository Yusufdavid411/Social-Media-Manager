import { Injectable } from '@nestjs/common';

@Injectable()
export class AuthService {
  issueAccessTokenPlaceholder(userId: string) {
    return {
      userId,
      tokenType: 'Bearer',
      status: 'placeholder',
    };
  }
}
