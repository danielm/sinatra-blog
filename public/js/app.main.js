$(function() {
	$('.btn-delete').on('click', function(e){
		if(!confirm('Delete: Are you sure?')){
			e.preventDefault();
		}
	});
});