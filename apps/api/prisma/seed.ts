import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '../generated/prisma/client';
import { SubscriptionPlanCode } from '../generated/prisma/enums';

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  throw new Error('DATABASE_URL is required.');
}

const prisma = new PrismaClient({
  adapter: new PrismaPg({ connectionString }),
});

async function main() {
  await prisma.subscriptionPlan.upsert({
    where: { code: SubscriptionPlanCode.FREE },
    update: {
      name: 'Free',
      monthlyPriceCents: 0,
      connectedAccountsLimit: 2,
      scheduledPostsPerMonth: 30,
      aiGenerationsPerMonth: 0,
      maxVideoUploadMb: 100,
      teamMembersLimit: 1,
      analyticsAccess: false,
      priorityPublishing: false,
    },
    create: {
      code: SubscriptionPlanCode.FREE,
      name: 'Free',
      monthlyPriceCents: 0,
      connectedAccountsLimit: 2,
      scheduledPostsPerMonth: 30,
      aiGenerationsPerMonth: 0,
      maxVideoUploadMb: 100,
      teamMembersLimit: 1,
      analyticsAccess: false,
      priorityPublishing: false,
    },
  });

  await prisma.subscriptionPlan.upsert({
    where: { code: SubscriptionPlanCode.PRO },
    update: {
      name: 'Pro',
      monthlyPriceCents: 1900,
      connectedAccountsLimit: 10,
      scheduledPostsPerMonth: 500,
      aiGenerationsPerMonth: 300,
      maxVideoUploadMb: 500,
      teamMembersLimit: 3,
      analyticsAccess: true,
      priorityPublishing: false,
    },
    create: {
      code: SubscriptionPlanCode.PRO,
      name: 'Pro',
      monthlyPriceCents: 1900,
      connectedAccountsLimit: 10,
      scheduledPostsPerMonth: 500,
      aiGenerationsPerMonth: 300,
      maxVideoUploadMb: 500,
      teamMembersLimit: 3,
      analyticsAccess: true,
      priorityPublishing: false,
    },
  });

  await prisma.subscriptionPlan.upsert({
    where: { code: SubscriptionPlanCode.BUSINESS },
    update: {
      name: 'Business',
      monthlyPriceCents: 4900,
      connectedAccountsLimit: 50,
      scheduledPostsPerMonth: 3000,
      aiGenerationsPerMonth: 1500,
      maxVideoUploadMb: 2048,
      teamMembersLimit: 15,
      analyticsAccess: true,
      priorityPublishing: true,
    },
    create: {
      code: SubscriptionPlanCode.BUSINESS,
      name: 'Business',
      monthlyPriceCents: 4900,
      connectedAccountsLimit: 50,
      scheduledPostsPerMonth: 3000,
      aiGenerationsPerMonth: 1500,
      maxVideoUploadMb: 2048,
      teamMembersLimit: 15,
      analyticsAccess: true,
      priorityPublishing: true,
    },
  });
}

main()
  .then(async () => {
    await prisma.$disconnect();
  })
  .catch(async (error) => {
    console.error(error);
    await prisma.$disconnect();
    process.exit(1);
  });
