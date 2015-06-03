$(function(){
  $('.tinymce').tinymce({
    toolbar: "bold italic strikethrough | formatselect | forecolor bullist numlist blockquote | hr link media image | code fullscreen", //spellchecker, emoticons
    menubar: false,
    plugins: "link,image,textcolor,code, hr, media, fullscreen", //, emoticons, colorpickerspellchecker
    theme: "modern",
    convert_urls: false,
    relative_urls: false,
    verify_html: false,
    //forced_root_block: false, //default is 'p'
    height: 300,
    paste_auto_cleanup_on_paste : true,
	paste_remove_styles: true,
	paste_remove_styles_if_webkit: true,
	paste_strip_class_attributes: 'all',
	paste_text_sticky: true,
	paste_text_sticky_default: true
    /*spellchecker_language: 'en',
    spellchecker_languages: 'English=en,Español=es'*/
  });
});
