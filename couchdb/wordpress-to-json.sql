-- Posts
SELECT CONCAT(
  '{',
  '"_id": "post-', ID, '", ',
  '"id": ', ID, ', ',
  '"cats": {', COALESCE((SELECT GROUP_CONCAT(DISTINCT CONCAT('"',t.slug,'": ',tt.term_id) SEPARATOR ', ') FROM wp_term_relationships AS tr INNER JOIN wp_term_taxonomy AS tt ON (tt.taxonomy = 'category') AND (tr.term_taxonomy_id = tt.term_taxonomy_id) INNER JOIN wp_terms AS t ON (t.term_id = tt.term_id) WHERE (tr.object_id = p.ID)), ''), '}, ',
  '"tags": [', COALESCE((SELECT GROUP_CONCAT(DISTINCT CONCAT('"',t.slug,'"') SEPARATOR ', ') FROM wp_term_relationships AS tr INNER JOIN wp_term_taxonomy AS tt ON (tt.taxonomy = 'post_tag') AND (tr.term_taxonomy_id = tt.term_taxonomy_id) INNER JOIN wp_terms AS t ON (t.term_id = tt.term_id) WHERE (tr.object_id = p.ID)), ''), '], ',
  '"author": ', post_author, ', ',
  '"posted": "', post_date, '", ',
  '"posted_gmt": "', DATE_FORMAT(post_date_gmt, '%Y/%m/%d %T +0000'), '", ',
  '"content": "', REPLACE(REPLACE(REPLACE(REPLACE(post_content, '\\', '\\\\'), '"', '\\"'), '=\\"/', '=\\"http://rickosborne.org/'), '\r\n', '\\n'), '", ',
  '"title": "', REPLACE(REPLACE(post_title, '\\', '\\\\'), '"', '\\"'), '", ',
  '"status": "', post_status, '", ',
  '"name": "', post_name, '", ',
  '"modified": "', post_modified, '", ',
  '"modified_gmt": "', DATE_FORMAT(post_modified_gmt, '%Y/%m/%d %T +0000'), '", ',
  '"guid": "', guid, '", ',
  '"type": "', post_type, '"',
  '}') AS json
FROM wp_posts AS p
WHERE (post_parent = 0)
ORDER BY ID DESC
LIMIT 10;



-- Authors
SELECT CONCAT('{'
  '"_id": "author-', ID, '", ',
  '"id": ', ID, ', '
  '"name": "', display_name, '", ',
  '"posts": {', COALESCE((SELECT GROUP_CONCAT(DISTINCT CONCAT('"',p.post_name,'": ',p.id) SEPARATOR ', ') FROM wp_posts AS p WHERE (p.post_author = u.ID) AND (p.id > 1126) AND (p.post_parent = 0)), ''), '}, ',
  CASE WHEN user_url <> '' THEN CONCAT('"url": "', user_url, '", ') ELSE '' END,
  '"gravatar_url": "http://www.gravatar.com/avatar/', MD5(LOWER(TRIM(user_email))), '", ',
  '"registered": "', user_registered, '", ',
  '"type": "author"',
  '}') AS json
FROM wp_users AS u
ORDER BY ID
LIMIT 3;

-- Categories
SELECT CONCAT('{',
  '"_id": "cat-', cat_ID, '", ',
  '"id": ', cat_ID, ', ',
  '"name": "', cat_name, '", ',
  '"posts": {', COALESCE((SELECT GROUP_CONCAT(DISTINCT CONCAT('"',p.post_name,'": ',p.id) SEPARATOR ', ') FROM wp_term_relationships AS tr INNER JOIN wp_term_taxonomy AS tt ON (tt.taxonomy = 'category') AND (tr.term_taxonomy_id = tt.term_taxonomy_id) INNER JOIN wp_posts AS p ON (p.ID = tr.object_id) INNER JOIN wp_terms AS t ON (tt.term_id = t.term_id) WHERE (t.slug = c.category_nicename) AND (p.id > 1126)), ''), '}, ',
  CASE WHEN category_parent > 0 THEN CONCAT('"parent_id": ', category_parent, ', "parent": "cat-', category_parent, '", ') ELSE '' END,
  '"nicename": "', category_nicename, '",',
  '"type": "category"'
  '}') AS json
FROM wp_categories AS c;

