$('a.delete').on('click', function(){
  if (!confirm('Really delete?')) {
    return false;
  }
});
