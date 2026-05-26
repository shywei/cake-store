-- ============================================
-- 小胖私家烘焙 - Supabase 数据库初始化
-- 在 Supabase Dashboard → SQL Editor 中运行
-- ============================================

-- 1. 创建蛋糕表
CREATE TABLE IF NOT EXISTS public.cakes (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name TEXT NOT NULL,
  price NUMERIC(10, 2) NOT NULL DEFAULT 0,
  category TEXT DEFAULT '',
  subcategory TEXT DEFAULT '',
  promoted BOOLEAN DEFAULT false,
  description TEXT DEFAULT '',
  badge TEXT DEFAULT '',
  image_url TEXT DEFAULT '',
  images JSONB DEFAULT '[]'::jsonb,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. 开启行级安全 (RLS)
ALTER TABLE public.cakes ENABLE ROW LEVEL SECURITY;

-- 3. 任何人都可以浏览蛋糕
DROP POLICY IF EXISTS "Anyone can view cakes" ON public.cakes;
CREATE POLICY "Anyone can view cakes" ON public.cakes
  FOR SELECT USING (true);

-- 4. 只有登录的管理员可以新增
DROP POLICY IF EXISTS "Auth users can insert cakes" ON public.cakes;
CREATE POLICY "Auth users can insert cakes" ON public.cakes
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- 5. 只有登录的管理员可以编辑
DROP POLICY IF EXISTS "Auth users can update cakes" ON public.cakes;
CREATE POLICY "Auth users can update cakes" ON public.cakes
  FOR UPDATE USING (auth.role() = 'authenticated');

-- 6. 只有登录的管理员可以删除
DROP POLICY IF EXISTS "Auth users can delete cakes" ON public.cakes;
CREATE POLICY "Auth users can delete cakes" ON public.cakes
  FOR DELETE USING (auth.role() = 'authenticated');

-- ============================================
-- 图片存储（Storage Bucket）
-- ============================================

INSERT INTO storage.buckets (id, name, public)
VALUES ('cake-images', 'cake-images', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Public can view cake images" ON storage.objects;
CREATE POLICY "Public can view cake images" ON storage.objects
  FOR SELECT USING (bucket_id = 'cake-images');

DROP POLICY IF EXISTS "Auth users can upload cake images" ON storage.objects;
CREATE POLICY "Auth users can upload cake images" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'cake-images'
    AND auth.role() = 'authenticated'
  );

DROP POLICY IF EXISTS "Auth users can delete cake images" ON storage.objects;
CREATE POLICY "Auth users can delete cake images" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'cake-images'
    AND auth.role() = 'authenticated'
  );

-- ============================================
-- 迁移：已有数据升级
-- 新项目不需要执行，上面建表已包含
-- ============================================
ALTER TABLE public.cakes ADD COLUMN IF NOT EXISTS images JSONB DEFAULT '[]'::jsonb;
ALTER TABLE public.cakes ADD COLUMN IF NOT EXISTS subcategory TEXT DEFAULT '';
ALTER TABLE public.cakes ADD COLUMN IF NOT EXISTS promoted BOOLEAN DEFAULT false;

-- 迁移 images（单图→数组）
UPDATE public.cakes
SET images = CASE
  WHEN image_url IS NOT NULL AND image_url != '' THEN jsonb_build_array(image_url)
  ELSE '[]'::jsonb
END
WHERE images IS NULL OR images = '[]'::jsonb;

-- 迁移 subcategory（已有分类→对应品种）
UPDATE public.cakes SET category='奶油蛋糕', subcategory='奶油蛋糕' WHERE category='奶油蛋糕';
UPDATE public.cakes SET category='甜点下午茶', subcategory='千层' WHERE category='千层';
UPDATE public.cakes SET category='甜点下午茶', subcategory='切块蛋糕' WHERE category='切块蛋糕';
UPDATE public.cakes SET category='甜点下午茶', subcategory='慕斯蛋糕' WHERE category='慕斯蛋糕';
UPDATE public.cakes SET category='宴会甜品', subcategory='定制蛋糕' WHERE category='定制蛋糕';
UPDATE public.cakes SET subcategory=category WHERE subcategory='' AND category NOT IN ('奶油蛋糕','甜点下午茶','宴会甜品');

-- ============================================
-- 示例数据
-- ============================================
INSERT INTO public.cakes (name, price, category, subcategory, promoted, description, badge, image_url, images, sort_order) VALUES
  ('莓果森林', 268, '奶油蛋糕', '水果蛋糕', true, '新鲜树莓与蓝莓的双重果香，搭配轻盈奶油，酸甜平衡恰到好处', '人气推荐', 'https://images.unsplash.com/photo-1565958011703-44f9829ba187?w=400&q=80', '["https://images.unsplash.com/photo-1565958011703-44f9829ba187?w=400&q=80","https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=400&q=80"]'::jsonb, 1),
  ('日式抹茶千层', 298, '甜点下午茶', '千层', true, '宇治抹茶与细腻奶油层层叠加，微苦回甘的成熟风味', '', 'https://images.unsplash.com/photo-1571115177098-24ec42ed204d?w=400&q=80', '["https://images.unsplash.com/photo-1571115177098-24ec42ed204d?w=400&q=80"]'::jsonb, 2),
  ('玫瑰荔枝', 328, '奶油蛋糕', '水果蛋糕', false, '食用玫瑰花瓣浸润荔枝果肉，花香与果香交织的浪漫滋味', '', 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=400&q=80', '["https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=400&q=80"]'::jsonb, 3),
  ('经典提拉米苏', 248, '甜点下午茶', '提拉米苏', true, '马斯卡彭芝士与浓缩咖啡的意式经典，入口即化的丝滑享受', '', 'https://images.unsplash.com/photo-1556217477-d325251ece38?w=400&q=80', '["https://images.unsplash.com/photo-1556217477-d325251ece38?w=400&q=80"]'::jsonb, 4),
  ('柠檬天使', 218, '甜点下午茶', '切块蛋糕', false, '清新柠檬凝乳搭配松软天使蛋糕，夏日里的一抹清凉', '新品', 'https://images.unsplash.com/photo-1464349095431-e9a21285b5f3?w=400&q=80', '["https://images.unsplash.com/photo-1464349095431-e9a21285b5f3?w=400&q=80"]'::jsonb, 5),
  ('黑森林', 288, '奶油蛋糕', '奶油蛋糕', false, '浓郁黑巧克力与酒渍樱桃的经典组合，微醺的甜蜜', '', 'https://images.unsplash.com/photo-1606890737304-57a1ca8a5b62?w=400&q=80', '["https://images.unsplash.com/photo-1606890737304-57a1ca8a5b62?w=400&q=80"]'::jsonb, 6),
  ('芒果椰子', 258, '奶油蛋糕', '水果蛋糕', false, '热带芒果与椰奶的完美邂逅，仿佛置身海岛度假', '', 'https://images.unsplash.com/photo-1588195538326-c5b1e9f80a58?w=400&q=80', '["https://images.unsplash.com/photo-1588195538326-c5b1e9f80a58?w=400&q=80"]'::jsonb, 7),
  ('法式巧克力慕斯', 318, '甜点下午茶', '慕斯蛋糕', false, '70%黑巧克力制作的丝滑慕斯，浓郁醇厚，入口即化', '', 'https://images.unsplash.com/photo-1542826438-bd32f43d626f?w=400&q=80', '["https://images.unsplash.com/photo-1542826438-bd32f43d626f?w=400&q=80"]'::jsonb, 8),
  ('蛋黄酥礼盒', 128, '甜点下午茶', '蛋黄酥', true, '手工酥皮层层起酥，红豆沙包裹咸蛋黄，一口酥香', '新品', '', '[]'::jsonb, 9),
  ('雪媚娘', 68, '甜点下午茶', '雪媚娘', true, '冰皮软糯拉丝，包裹轻盈奶油和新鲜水果，冷藏后口感更佳', '', '', '[]'::jsonb, 10)
ON CONFLICT DO NOTHING;
