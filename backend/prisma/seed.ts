import "dotenv/config";
import bcrypt from "bcryptjs";
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

async function main() {
  const adminEmail = process.env.ADMIN_EMAIL;
  const adminPassword = process.env.ADMIN_PASSWORD;

  if (!adminEmail || !adminPassword) {
    throw new Error("Set ADMIN_EMAIL and ADMIN_PASSWORD in backend/.env before seeding.");
  }

  const passwordHash = await bcrypt.hash(adminPassword, 12);
  await prisma.adminUser.upsert({
    where: { email: adminEmail },
    create: { email: adminEmail, passwordHash },
    update: { passwordHash },
  });
  console.log(`Admin user ready: ${adminEmail}`);

  await prisma.heroContent.upsert({
    where: { id: 1 },
    create: {
      id: 1,
      name: "Your Name",
      title: "Software Engineer",
      subtitle: "I build fast, reliable apps for web and mobile.",
      summary:
        "Edit this from the admin panel: a short summary of who you are, what you do, and what you're looking for.",
    },
    update: {},
  });

  await prisma.aboutContent.upsert({
    where: { id: 1 },
    create: {
      id: 1,
      bio: "Edit this from the admin panel: a longer bio about your background, experience, and interests.",
    },
    update: {},
  });

  const skillCount = await prisma.skill.count();
  if (skillCount === 0) {
    await prisma.skill.createMany({
      data: [
        { name: "Flutter", category: "Frameworks", sortOrder: 0 },
        { name: "Dart", category: "Languages", sortOrder: 1 },
        { name: "TypeScript", category: "Languages", sortOrder: 2 },
        { name: "Node.js", category: "Backend", sortOrder: 3 },
        { name: "MySQL", category: "Databases", sortOrder: 4 },
      ],
    });
  }

  const projectCount = await prisma.project.count();
  if (projectCount === 0) {
    await prisma.project.create({
      data: {
        title: "Sample Project",
        description: "Replace this with a real project from the admin panel.",
        techTags: JSON.stringify(["Flutter", "Node.js", "MySQL"]),
        featured: true,
        sortOrder: 0,
      },
    });
  }

  console.log("Seed complete. Placeholder content created — edit it via the admin panel.");
}

main()
  .catch((err) => {
    console.error(err);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
