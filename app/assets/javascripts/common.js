$(document).ready(function(){
    $('.message').click(function(){
        $('.message').fadeOut(1000);
    })
    $(function() {
        setTimeout(function() {
            $(".message").hide('blind', {}, 500)
         }, 3000);
    });
});
