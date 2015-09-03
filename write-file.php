<?php
// Get params
$doc_id = htmlspecialchars($_POST['doc_id']);
$doc_content_md = $_POST['doc_content_md'];
$doc_content_html = $_POST['doc_content_html'];

// Write Markdown File
file_put_contents('documents/'.$doc_id.".md", $doc_content_md);

// Write HTML File
file_put_contents('documents/'.$doc_id.".html", $doc_content_html);
?>