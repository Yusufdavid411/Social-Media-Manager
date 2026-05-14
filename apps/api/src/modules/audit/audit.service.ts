import { Injectable } from '@nestjs/common';
import { Prisma } from '../../../generated/prisma/client';
import { AuditAction } from '../../../generated/prisma/enums';
import { PrismaService } from '../database/prisma.service';

type WriteAuditLogInput = {
  action: AuditAction;
  entityType: string;
  entityId?: string;
  workspaceId?: string;
  actorId?: string;
  metadata?: Prisma.InputJsonObject;
};

@Injectable()
export class AuditService {
  constructor(private readonly prisma: PrismaService) {}

  async write(input: WriteAuditLogInput) {
    return this.prisma.auditLog.create({
      data: {
        action: input.action,
        entityType: input.entityType,
        entityId: input.entityId,
        workspaceId: input.workspaceId,
        actorId: input.actorId,
        metadata: input.metadata,
      },
    });
  }
}
