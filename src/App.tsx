import { useState, useEffect, useCallback } from "react";
import type { Category, Dish, DishFormData } from "./types";
import {
  getCategories,
  getDishes,
  addDish,
  updateDish,
  deleteDish,
  addCategory,
  updateCategory,
  deleteCategory,
} from "./db";
import "./App.css";

function App() {
  const [categories, setCategories] = useState<Category[]>([]);
  const [dishes, setDishes] = useState<Dish[]>([]);
  const [activeCategoryId, setActiveCategoryId] = useState<number | null>(null);
  const [showDishForm, setShowDishForm] = useState(false);
  const [editingDish, setEditingDish] = useState<Dish | null>(null);
  const [showCategoryForm, setShowCategoryForm] = useState(false);
  const [editingCategory, setEditingCategory] = useState<Category | null>(null);

  const loadCategories = useCallback(async () => {
    const cats = await getCategories();
    setCategories(cats);
    if (cats.length > 0 && activeCategoryId === null) {
      setActiveCategoryId(cats[0].id);
    }
  }, [activeCategoryId]);

  const loadDishes = useCallback(async () => {
    if (activeCategoryId === null) return;
    const items = await getDishes(activeCategoryId);
    setDishes(items);
  }, [activeCategoryId]);

  useEffect(() => {
    loadCategories();
  }, [loadCategories]);

  useEffect(() => {
    loadDishes();
  }, [loadDishes]);

  const handleDeleteDish = async (id: number) => {
    await deleteDish(id);
    await loadDishes();
  };

  const handleDishSubmit = async (data: DishFormData) => {
    if (editingDish) {
      await updateDish(editingDish.id, data);
    } else {
      await addDish(data);
    }
    setShowDishForm(false);
    setEditingDish(null);
    await loadDishes();
  };

  const handleCategorySubmit = async (name: string, icon: string) => {
    if (editingCategory) {
      await updateCategory(editingCategory.id, name, icon);
    } else {
      await addCategory(name, icon);
    }
    setShowCategoryForm(false);
    setEditingCategory(null);
    await loadCategories();
  };

  const handleDeleteCategory = async (id: number) => {
    await deleteCategory(id);
    setShowCategoryForm(false);
    setEditingCategory(null);
    if (activeCategoryId === id) {
      setActiveCategoryId(categories.find((c) => c.id !== id)?.id ?? null);
    }
    await loadCategories();
    await loadDishes();
  };

  const activeCategory = categories.find((c) => c.id === activeCategoryId);

  return (
    <div className="app">
      <aside className="sidebar">
        <div className="sidebar-header" data-tauri-drag-region>
          <h1>🐷 猪咪餐厅</h1>
        </div>
        <nav className="category-list">
          {categories.map((cat) => (
            <button
              key={cat.id}
              type="button"
              className={`category-item ${cat.id === activeCategoryId ? "active" : ""}`}
              onClick={() => setActiveCategoryId(cat.id)}
              onContextMenu={(e) => {
                e.preventDefault();
                setEditingCategory(cat);
                setShowCategoryForm(true);
              }}
            >
              <span className="category-icon">{cat.icon}</span>
              <span className="category-name">{cat.name}</span>
            </button>
          ))}
        </nav>
        <button
          type="button"
          className="btn btn-add-category"
          onClick={() => {
            setEditingCategory(null);
            setShowCategoryForm(true);
          }}
        >
          + 新增分类
        </button>
      </aside>

      <main className="content">
        <header className="content-header">
          <h2>{activeCategory ? `${activeCategory.icon} ${activeCategory.name}` : "全部菜品"}</h2>
          <button
            type="button"
            className="btn btn-primary"
            onClick={() => {
              setEditingDish(null);
              setShowDishForm(true);
            }}
          >
            + 添加菜品
          </button>
        </header>

        <div className="dish-grid">
          {dishes.map((dish) => (
            <div key={dish.id} className="dish-card">
              <div className="dish-image">
                {dish.image_path ? (
                  <img src={dish.image_path} alt={dish.name} />
                ) : (
                  <div className="dish-placeholder">🍽️</div>
                )}
              </div>
              <div className="dish-info">
                <h3 className="dish-name">{dish.name}</h3>
                <span className="dish-price">¥{dish.price.toFixed(1)}</span>
              </div>
              <div className="dish-actions">
                <button
                  type="button"
                  className="btn btn-sm"
                  onClick={() => {
                    setEditingDish(dish);
                    setShowDishForm(true);
                  }}
                >
                  编辑
                </button>
                <button type="button" className="btn btn-sm btn-danger" onClick={() => handleDeleteDish(dish.id)}>
                  删除
                </button>
              </div>
            </div>
          ))}
          {dishes.length === 0 && (
            <div className="empty-state">
              <p>暂无菜品，点击「添加菜品」开始吧 🐷</p>
            </div>
          )}
        </div>
      </main>

      {showDishForm && (
        <DishFormModal
          dish={editingDish}
          categories={categories}
          defaultCategoryId={activeCategoryId}
          onSubmit={handleDishSubmit}
          onClose={() => {
            setShowDishForm(false);
            setEditingDish(null);
          }}
        />
      )}

      {showCategoryForm && (
        <CategoryFormModal
          category={editingCategory}
          onSubmit={handleCategorySubmit}
          onDelete={editingCategory ? () => handleDeleteCategory(editingCategory.id) : undefined}
          onClose={() => {
            setShowCategoryForm(false);
            setEditingCategory(null);
          }}
        />
      )}
    </div>
  );
}

function DishFormModal({
  dish,
  categories,
  defaultCategoryId,
  onSubmit,
  onClose,
}: {
  dish: Dish | null;
  categories: Category[];
  defaultCategoryId: number | null;
  onSubmit: (data: DishFormData) => void;
  onClose: () => void;
}) {
  const [name, setName] = useState(dish?.name ?? "");
  const [price, setPrice] = useState(dish?.price?.toString() ?? "");
  const [categoryId, setCategoryId] = useState(dish?.category_id ?? defaultCategoryId ?? categories[0]?.id ?? 0);
  const [imagePath, setImagePath] = useState<string | null>(dish?.image_path ?? null);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) return;
    onSubmit({
      name: name.trim(),
      price: parseFloat(price) || 0,
      category_id: categoryId,
      image_path: imagePath,
    });
  };

  return (
    <button type="button" className="modal-overlay" onClick={onClose}>
      <div className="modal" role="dialog" onClick={(e) => e.stopPropagation()} onKeyDown={(e) => e.stopPropagation()}>
        <h3>{dish ? "编辑菜品" : "添加菜品"}</h3>
        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label htmlFor="dish-name">菜品名称</label>
            <input
              id="dish-name"
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="输入菜品名称"
            />
          </div>
          <div className="form-group">
            <label htmlFor="dish-price">价格 (元)</label>
            <input
              id="dish-price"
              type="number"
              step="0.1"
              min="0"
              value={price}
              onChange={(e) => setPrice(e.target.value)}
              placeholder="0.0"
            />
          </div>
          <div className="form-group">
            <label htmlFor="dish-category">分类</label>
            <select id="dish-category" value={categoryId} onChange={(e) => setCategoryId(Number(e.target.value))}>
              {categories.map((cat) => (
                <option key={cat.id} value={cat.id}>
                  {cat.icon} {cat.name}
                </option>
              ))}
            </select>
          </div>
          <div className="form-group">
            <label htmlFor="dish-image">图片路径</label>
            <input
              id="dish-image"
              type="text"
              value={imagePath ?? ""}
              onChange={(e) => setImagePath(e.target.value || null)}
              placeholder="可选，输入图片路径"
            />
          </div>
          <div className="form-actions">
            <button type="button" className="btn" onClick={onClose}>
              取消
            </button>
            <button type="submit" className="btn btn-primary">
              {dish ? "保存" : "添加"}
            </button>
          </div>
        </form>
      </div>
    </button>
  );
}

function CategoryFormModal({
  category,
  onSubmit,
  onDelete,
  onClose,
}: {
  category: Category | null;
  onSubmit: (name: string, icon: string) => void;
  onDelete?: () => void;
  onClose: () => void;
}) {
  const [name, setName] = useState(category?.name ?? "");
  const [icon, setIcon] = useState(category?.icon ?? "🍽️");

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) return;
    onSubmit(name.trim(), icon);
  };

  return (
    <button type="button" className="modal-overlay" onClick={onClose}>
      <div className="modal" role="dialog" onClick={(e) => e.stopPropagation()} onKeyDown={(e) => e.stopPropagation()}>
        <h3>{category ? "编辑分类" : "新增分类"}</h3>
        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label htmlFor="cat-icon">图标</label>
            <input
              id="cat-icon"
              type="text"
              value={icon}
              onChange={(e) => setIcon(e.target.value)}
              className="icon-input"
            />
          </div>
          <div className="form-group">
            <label htmlFor="cat-name">分类名称</label>
            <input
              id="cat-name"
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="输入分类名称"
            />
          </div>
          <div className="form-actions">
            {onDelete && (
              <button type="button" className="btn btn-danger" onClick={onDelete}>
                删除分类
              </button>
            )}
            <div className="spacer" />
            <button type="button" className="btn" onClick={onClose}>
              取消
            </button>
            <button type="submit" className="btn btn-primary">
              {category ? "保存" : "添加"}
            </button>
          </div>
        </form>
      </div>
    </button>
  );
}

export default App;
