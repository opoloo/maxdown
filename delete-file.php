<?php
$doc_id = $_POST['doc_id'];

unlink('documents/'.$doc_id.'.md');
unlink('documents/'.$doc_id.'.html');
?>