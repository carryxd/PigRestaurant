export interface Category {
  id: number;
  name: string;
  icon: string;
  sort_order: number;
}

export interface Dish {
  id: number;
  category_id: number;
  name: string;
  price: number;
  image_path: string | null;
  created_at: string;
  updated_at: string;
}

export interface DishFormData {
  name: string;
  price: number;
  category_id: number;
  image_path: string | null;
}
