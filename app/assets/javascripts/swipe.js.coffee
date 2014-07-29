Swipe = 
	init: ->
		$('.search-form').on 'submit', @hideResults
		$('body').on 'click', '.swipe-next', @swipeNext
		@hideResults()
	
	hideResults: ->
		$('.swiped-result').hide()
		$('.swiped-result').first().show()

	swipeNext: ->
		current = $('.swiped-result:visible')
		next = current.next()
		current.addClass('animated slideOutRight')
		current.bind 'oanimationend animationend webkitAnimationEnd', ->
			current.hide()
			if next.attr('class') == 'swiped-result'
				next.show()
				next.addClass ('animated slideInLeft')
			else
				$('#empty').show()






ready = ->
	Swipe.init()
$(document).ready ready
$(document).on 'page:load', ready