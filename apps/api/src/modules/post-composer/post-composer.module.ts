import { Module } from '@nestjs/common';
import { PostComposerService } from './post-composer.service';

@Module({
  providers: [PostComposerService],
  exports: [PostComposerService],
})
export class PostComposerModule {}
