;(function(){
  var loading = document.querySelector('.loading')
  var h = new HTTPster()
  var render = function render( data ){
    var loader = document.querySelectorAll('.loading')
    for( var i = 0, len = loader.length; i < len; i++ ){
      loader[i].style.display = 'none'
    }
    var grade = data.grade
    document.querySelector('[data-grade]').innerHTML = grade
    var missing = document.querySelector('[data-missing]')
    for( var i = 0, len = data.missing.length; i < len; i++ ){
      var assignment = document.createElement("li") 
      var week = data.missing[i].split(/d/)[0]
      var day = 'd' + data.missing[i].split(/d/)[1] 
      assignment.innerHTML = "<a>"+data.missing[i]+"</a>"
      missing.appendChild( assignment )
    }
  }
  h.get( '/grades', render )
})();