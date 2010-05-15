SELECT CONCAT(
  '{',
  '"_id": "post-', ID, '", ' 
  '"author": ', post_author, ', ',
  '"posted": "', post_date, '", ',
  '"posted_gmt": "', post_date_gmt, '", ',
  '"content": "', REPLACE(REPLACE(REPLACE(REPLACE(post_content, '\\', '\\\\'), '"', '\\"'), '=\\"/', '=\\"http://rickosborne.org/'), '\r\n', '\\n'), '", ',
  '"title": "', REPLACE(REPLACE(post_title, '\\', '\\\\'), '"', '\\"'), '", ',
  '"status": "', post_status, '", ',
  '"name": "', post_name, '", ',
  '"modified": "', post_modified, '", ',
  '"modified_gmt": "', post_modified_gmt, '", ',
  '"guid": "', guid, '", ',
  '"type": "', post_type, '"'
  '}') AS json
FROM wp_posts
WHERE (post_parent = 0)
ORDER BY ID DESC
LIMIT 10;

SELECT CONCAT('{'
  '"_id": "author-', ID, '", ',
  '"name": "', display_name, '", ',
  CASE WHEN user_url <> '' THEN CONCAT('"url": "', user_url, '", ') ELSE '' END,
  '"gravatar_url": "http://www.gravatar.com/avatar/', MD5(LOWER(TRIM(user_email))), '", ',
  '"registered": "', user_registered, '"'
  '}') AS json
FROM wp_users
ORDER BY ID
LIMIT 3;
