import Database from "@tauri-apps/plugin-sql";
import type { Category, Dish, DishFormData } from "./types";

let db: Database | null = null;

export async function getDb(): Promise<Database> {
  if (!db) {
    db = await Database.load("sqlite:pig_restaurant.db");
    await initTables();
  }
  return db;
}

async function initTables() {
  const d = db!;
  await d.execute(`
    CREATE TABLE IF NOT EXISTS categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      icon TEXT NOT NULL DEFAULT '🍽️',
      sort_order INTEGER NOT NULL DEFAULT 0
    )
  `);
  await d.execute(`
    CREATE TABLE IF NOT EXISTS dishes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      category_id INTEGER NOT NULL,
      name TEXT NOT NULL,
      price REAL NOT NULL DEFAULT 0,
      image_path TEXT,
      created_at TEXT NOT NULL DEFAULT (datetime('now','localtime')),
      updated_at TEXT NOT NULL DEFAULT (datetime('now','localtime')),
      FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
    )
  `);

  const result = await d.select<{ count: number }[]>(
    "SELECT COUNT(*) as count FROM categories"
  );
  if (result[0].count === 0) {
    await seedDefaultData(d);
  }
}

async function seedDefaultData(d: Database) {
  const categories = [
    { name: "家常热菜", icon: "🥘", sort_order: 1 },
    { name: "凉菜小食", icon: "🥗", sort_order: 2 },
    { name: "汤羹粥品", icon: "🍲", sort_order: 3 },
    { name: "主食面点", icon: "🍚", sort_order: 4 },
    { name: "海鲜水产", icon: "🦐", sort_order: 5 },
    { name: "甜品饮品", icon: "🍰", sort_order: 6 },
  ];

  for (const cat of categories) {
    await d.execute(
      "INSERT INTO categories (name, icon, sort_order) VALUES ($1, $2, $3)",
      [cat.name, cat.icon, cat.sort_order]
    );
  }

  const dishes: { category: string; items: { name: string; price: number }[] }[] = [
    {
      category: "家常热菜",
      items: [
        { name: "番茄炒蛋", price: 12 },
        { name: "红烧肉", price: 35 },
        { name: "宫保鸡丁", price: 28 },
        { name: "鱼香肉丝", price: 25 },
        { name: "麻婆豆腐", price: 18 },
        { name: "回锅肉", price: 30 },
        { name: "青椒肉丝", price: 22 },
        { name: "干煸四季豆", price: 18 },
        { name: "蒜蓉西兰花", price: 15 },
        { name: "可乐鸡翅", price: 28 },
        { name: "糖醋排骨", price: 38 },
        { name: "土豆烧牛肉", price: 42 },
        { name: "辣子鸡", price: 32 },
        { name: "蚂蚁上树", price: 18 },
        { name: "地三鲜", price: 20 },
      ],
    },
    {
      category: "凉菜小食",
      items: [
        { name: "拍黄瓜", price: 10 },
        { name: "凉拌木耳", price: 12 },
        { name: "皮蛋豆腐", price: 15 },
        { name: "口水鸡", price: 28 },
        { name: "凉拌腐竹", price: 12 },
        { name: "蒜泥白肉", price: 25 },
        { name: "老醋花生", price: 10 },
      ],
    },
    {
      category: "汤羹粥品",
      items: [
        { name: "番茄蛋花汤", price: 12 },
        { name: "紫菜蛋汤", price: 10 },
        { name: "排骨莲藕汤", price: 35 },
        { name: "酸辣汤", price: 15 },
        { name: "玉米排骨汤", price: 30 },
        { name: "冬瓜丸子汤", price: 20 },
        { name: "皮蛋瘦肉粥", price: 15 },
        { name: "南瓜小米粥", price: 12 },
      ],
    },
    {
      category: "主食面点",
      items: [
        { name: "蛋炒饭", price: 12 },
        { name: "葱油拌面", price: 10 },
        { name: "炸酱面", price: 15 },
        { name: "猪肉水饺", price: 20 },
        { name: "韭菜盒子", price: 15 },
        { name: "葱花饼", price: 10 },
        { name: "红糖馒头", price: 8 },
        { name: "肉包子", price: 12 },
      ],
    },
    {
      category: "海鲜水产",
      items: [
        { name: "清蒸鲈鱼", price: 48 },
        { name: "红烧带鱼", price: 35 },
        { name: "蒜蓉粉丝蒸虾", price: 55 },
        { name: "油焖大虾", price: 58 },
        { name: "酸菜鱼", price: 42 },
        { name: "水煮鱼", price: 45 },
      ],
    },
    {
      category: "甜品饮品",
      items: [
        { name: "红豆沙", price: 10 },
        { name: "银耳莲子羹", price: 12 },
        { name: "绿豆汤", price: 8 },
        { name: "酸梅汤", price: 8 },
        { name: "桂花糕", price: 15 },
        { name: "芒果西米露", price: 15 },
      ],
    },
  ];

  const cats = await d.select<Category[]>("SELECT * FROM categories");
  const catMap = new Map(cats.map((c) => [c.name, c.id]));

  for (const group of dishes) {
    const catId = catMap.get(group.category);
    if (!catId) continue;
    for (const item of group.items) {
      await d.execute(
        "INSERT INTO dishes (category_id, name, price) VALUES ($1, $2, $3)",
        [catId, item.name, item.price]
      );
    }
  }
}

export async function getCategories(): Promise<Category[]> {
  const d = await getDb();
  return d.select<Category[]>("SELECT * FROM categories ORDER BY sort_order");
}

export async function addCategory(name: string, icon: string): Promise<void> {
  const d = await getDb();
  const result = await d.select<{ max_order: number | null }[]>(
    "SELECT MAX(sort_order) as max_order FROM categories"
  );
  const nextOrder = (result[0].max_order ?? 0) + 1;
  await d.execute(
    "INSERT INTO categories (name, icon, sort_order) VALUES ($1, $2, $3)",
    [name, icon, nextOrder]
  );
}

export async function updateCategory(id: number, name: string, icon: string): Promise<void> {
  const d = await getDb();
  await d.execute("UPDATE categories SET name = $1, icon = $2 WHERE id = $3", [
    name,
    icon,
    id,
  ]);
}

export async function deleteCategory(id: number): Promise<void> {
  const d = await getDb();
  await d.execute("DELETE FROM dishes WHERE category_id = $1", [id]);
  await d.execute("DELETE FROM categories WHERE id = $1", [id]);
}

export async function getDishes(categoryId?: number): Promise<Dish[]> {
  const d = await getDb();
  if (categoryId) {
    return d.select<Dish[]>(
      "SELECT * FROM dishes WHERE category_id = $1 ORDER BY updated_at DESC",
      [categoryId]
    );
  }
  return d.select<Dish[]>("SELECT * FROM dishes ORDER BY updated_at DESC");
}

export async function addDish(data: DishFormData): Promise<void> {
  const d = await getDb();
  await d.execute(
    "INSERT INTO dishes (category_id, name, price, image_path) VALUES ($1, $2, $3, $4)",
    [data.category_id, data.name, data.price, data.image_path]
  );
}

export async function updateDish(id: number, data: DishFormData): Promise<void> {
  const d = await getDb();
  await d.execute(
    "UPDATE dishes SET category_id = $1, name = $2, price = $3, image_path = $4, updated_at = datetime('now','localtime') WHERE id = $5",
    [data.category_id, data.name, data.price, data.image_path, id]
  );
}

export async function deleteDish(id: number): Promise<void> {
  const d = await getDb();
  await d.execute("DELETE FROM dishes WHERE id = $1", [id]);
}
