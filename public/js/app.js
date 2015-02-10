;(function(){
  var loading = document.querySelector('.loading')
  var h = new HTTPster()
  console.log('here')
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
      var link = document.createElement('a')
      link.href = 'https://github.com/ga-students/wdidc4-hw/tree/master/assignments/'+ week +'/' + day
      link.innerHTML = data.missing[i]
      assignment.appendChild( link )
      missing.appendChild( assignment )
    }
  }
  h.get( '/grades', render )
})();