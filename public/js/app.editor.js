$(function(){
  $('.tinymce').tinymce({
    toolbar: "bold italic strikethrough | formatselect | forecolor bullist numlist blockquote | hr link media image | code", //spellchecker, emoticons
    menubar: false,
    plugins: "link,image,textcolor,code, hr, media", //, emoticons, colorpickerspellchecker
    theme: "modern",
    convert_urls: false,
    relative_urls: false,
    verify_html: false,
    forced_root_block: false //default is 'p'
    /*spellchecker_language: 'en',
    spellchecker_languages: 'English=en,Español=es'*/
  });
});
