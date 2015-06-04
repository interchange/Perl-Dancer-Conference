(function($){
	"use strict";
	
	if( navigator.userAgent.match(/Android/i) || navigator.userAgent.match(/webOS/i) || 
		navigator.userAgent.match(/iPhone/i) || navigator.userAgent.match(/iPad/i) || 
		navigator.userAgent.match(/iPod/i) || navigator.userAgent.match(/BlackBerry/i) || 
		navigator.userAgent.match(/Windows Phone/i) ){ 
		var gdlr_touch_device = true; 
	}else{ 
		var gdlr_touch_device = false; 
	}
	
	// retrieve GET variable from url
	$.extend({
	  getUrlVars: function(){
		var vars = [], hash;
		var hashes = window.location.href.slice(window.location.href.indexOf('?') + 1).split('&');
		for(var i = 0; i < hashes.length; i++)
		{
		  hash = hashes[i].split('=');
		  vars.push(hash[0]);
		  vars[hash[0]] = hash[1];
		}
		return vars;
	  },
	  getUrlVar: function(name){
		return $.getUrlVars()[name];
	  }
	});	
	
	// blog - port nav
	function gdlr_set_item_outer_nav(){
		$('.blog-item-wrapper > .gdlr-nav-container').each(function(){
			var container = $(this).siblings('.blog-item-holder');
			var child = $(this).children();
			child.css({ 'top':container.position().top, 'bottom':'auto', height: container.height() - 50 });
		});
		$('.portfolio-item-wrapper > .gdlr-nav-container').each(function(){
			var container = $(this).siblings('.portfolio-item-holder');
			var child = $(this).children();
			child.css({ 'top':container.position().top, 'bottom':'auto', height: container.height() - 40 });
		});		
	}	
	
	// runs flex slider function
	$.fn.gdlr_flexslider = function(){
		if(typeof($.fn.flexslider) == 'function'){
			$(this).each(function(){
				var flex_attr = {
					animation: 'fade',
					animationLoop: true,
					prevText: '<i class="icon-angle-left" ></i>', 
					nextText: '<i class="icon-angle-right" ></i>',
					useCSS: false
				};
				
				// slide duration
				if( $(this).attr('data-pausetime') ){
					flex_attr.slideshowSpeed = parseInt($(this).attr('data-pausetime'));
				}
				if( $(this).attr('data-slidespeed') ){
					flex_attr.animationSpeed = parseInt($(this).attr('data-slidespeed'));
				}

				// set the attribute for carousel type
				if( $(this).attr('data-type') == 'carousel' ){
					flex_attr.move = 1;
					flex_attr.animation = 'slide';
					
					if( $(this).closest('.gdlr-item-no-space').length > 0 ){
						flex_attr.itemWidth = $(this).width() / parseInt($(this).attr('data-columns'));
						flex_attr.itemMargin = 0;							
					}else{
						flex_attr.itemWidth = (($(this).width() + 30) / parseInt($(this).attr('data-columns'))) - 30;
						flex_attr.itemMargin = 30;	
					}		
					
					// if( $(this).attr('data-columns') == "1" ){ flex_attr.smoothHeight = true; }
				}else{
					if( $(this).attr('data-effect') ){
						flex_attr.animation = $(this).attr('data-effect');
					}
				}
				if( $(this).attr('data-columns') ){
					flex_attr.minItems = parseInt($(this).attr('data-columns'));
					flex_attr.maxItems = parseInt($(this).attr('data-columns'));	
				}				
				
				// set the navigation to different area
				if( $(this).attr('data-nav-container') ){
					var flex_parent = $(this).parents('.' + $(this).attr('data-nav-container')).prev('.gdlr-nav-container');
					
					if( flex_parent.find('.gdlr-flex-prev').length > 0 || flex_parent.find('.gdlr-flex-next').length > 0 ){
						flex_attr.controlNav = false;
						flex_attr.directionNav = false;
						flex_attr.start = function(slider){
							flex_parent.find('.gdlr-flex-next').click(function(){
								slider.flexAnimate(slider.getTarget("next"), true);
							});
							flex_parent.find('.gdlr-flex-prev').click(function(){
								slider.flexAnimate(slider.getTarget("prev"), true);
							});
							
							gdlr_set_item_outer_nav();
							$(window).resize(function(){ gdlr_set_item_outer_nav(); });
						}
					}else{
						flex_attr.controlNav = false;
						flex_attr.controlsContainer = flex_parent.find('.nav-container');	
					}
					
				}

				$(this).flexslider(flex_attr);	
			});	
		}
	}
	
	// runs nivo slider function
	$.fn.gdlr_nivoslider = function(){
		if(typeof($.fn.nivoSlider) == 'function'){
			$(this).each(function(){
				var nivo_attr = {};
				
				if( $(this).attr('data-pausetime') ){
					nivo_attr.pauseTime = parseInt($(this).attr('data-pausetime'));
				}
				if( $(this).attr('data-slidespeed') ){
					nivo_attr.animSpeed = parseInt($(this).attr('data-slidespeed'));
				}
				if( $(this).attr('data-effect') ){
					nivo_attr.effect = $(this).attr('data-effect');
				}

				$(this).nivoSlider(nivo_attr);	
			});	
		}
	}	
	
	// runs isotope function
	$.fn.gdlr_isotope = function(){
		if(typeof($.fn.isotope) == 'function'){
			$(this).each(function(){
				var layout = ($(this).attr('data-layout'))? $(this).attr('data-layout'): 'fitRows';
				if( layout == 'fitRows' ) return;
				
				// execute isotope
				var isotope_element = $(this);
				isotope_element.children('.clear').remove();
				isotope_element.isotope({
					layoutMode: layout
				});
				
				// resize event
				$(window).resize(function(){
					isotope_element.isotope();
				});				
			});	
		}
	}
	
	// runs fancybox function
	$.fn.gdlr_fancybox = function(){
		if(typeof($.fn.fancybox) == 'function'){
			var fancybox_attr = {
				nextMethod : 'resizeIn',
				nextSpeed : 250,
				prevMethod : false,
				prevSpeed : 250,	
				helpers : { media : {} }
			};
			
			if( typeof($.fancybox.helpers.thumbs) == 'object' ){
				fancybox_attr.helpers.thumbs = { width: 50, height: 50 };
			}

			$(this).fancybox(fancybox_attr);
		}	
	}
	
	// responsive video
	$.fn.gdlr_fluid_video = function(){
		$(this).find('iframe[src^="http://www.youtube.com"], iframe[src^="//www.youtube.com"],'  +
					 'iframe[src^="http://player.vimeo.com"], iframe[src^="//player.vimeo.com"]').each(function(){

			// ignore if inside layerslider
			if( $(this).closest('.ls-container, .master-slider').length <= 0 ){ 
				if( ($(this).is('embed') && $(this).parent('object').length) || $(this).parent('.fluid-width-video-wrapper').length ){ return; } 
				if( !$(this).attr('id') ){ $(this).attr('id', 'gdlr-video-' + Math.floor(Math.random()*999999)); }			
			
				var ratio = $(this).height() / $(this).width();
				$(this).removeAttr('height').removeAttr('width');
				try{
					$(this).wrap('<div class="gdlr-fluid-video-wrapper"></div>').parent().css('padding-top', (ratio * 100)+"%");
				}catch(e){
				}
			}
		
		});	
	}
	
	// pie chart
	$.fn.gdlr_pie_chart = function(){
		if(typeof($.fn.easyPieChart) == 'function'){
			$(this).each(function(){
				var gdlr_chart = $(this);
				
				$(this).easyPieChart({
					animate: 1200,
					lineWidth: gdlr_chart.attr('data-linewidth')? parseInt(gdlr_chart.attr('data-linewidth')): 8,
					size: gdlr_chart.attr('data-size')? parseInt(gdlr_chart.attr('data-size')): 155,
					barColor: gdlr_chart.attr('data-color')? gdlr_chart.attr('data-color'): '#a9e16e',
					trackColor: gdlr_chart.attr('data-bg-color')? gdlr_chart.attr('data-bg-color'): '#f2f2f2',
					backgroundColor: gdlr_chart.attr('data-background'),
					scaleColor: false,
					lineCap: 'square'
				});

				// for responsive purpose
				if($.browser.msie && (parseInt($.browser.version) <= 8)) return;
				function limit_gdlr_chart_size(){
					if( gdlr_chart.parent().width() < parseInt(gdlr_chart.attr('data-size')) ){
						var max_width = gdlr_chart.parent().width() + 'px';
						gdlr_chart.css({'max-width': max_width, 'max-height': max_width});
					}				
				}
				limit_gdlr_chart_size();
				$(window).resize(function(){ limit_gdlr_chart_size(); });
			});
		}
	}
		
	$(document).ready(function(){

		// video responsive
		$('body').gdlr_fluid_video();	
	
		// top woocommerce button
		$('.gdlr-top-woocommerce-wrapper').hover(function(){
			$(this).children('.gdlr-top-woocommerce').fadeIn(200);
		}, function(){
			$(this).children('.gdlr-top-woocommerce').fadeOut(200);
		});
	
		// script for accordion item
		$('.gdlr-accordion-item').each(function(){
			var multiple_tab = $(this).hasClass('gdlr-multiple-tab');
			$(this).children('.accordion-tab').children('.accordion-title').click(function(){
				var current_tab = $(this).parent();
				if( current_tab.hasClass('active') ){
					current_tab.removeClass('pre-active');
					$(this).children('i').removeClass('icon-minus').addClass('icon-plus');
					$(this).siblings('.accordion-content').slideUp(function(){ current_tab.removeClass('active'); });
				}else{
					current_tab.addClass('pre-active');
					$(this).children('i').removeClass('icon-plus').addClass('icon-minus');	
					$(this).siblings('.accordion-content').slideDown(function(){ current_tab.addClass('active'); });
								
				}
				
				// close another tab if multiple tab is not allowed ( accordion )
				if( !multiple_tab ){
					current_tab.siblings().removeClass('pre-active');
					current_tab.siblings().children('.accordion-title').children('i').removeClass('icon-minus').addClass('icon-plus');
					current_tab.siblings().children('.accordion-content').slideUp(function(){ $(this).parent().removeClass('active'); });
				}
			});
		});
		
		// script for tab item
		$('.tab-title-wrapper').children().click(function(){
			$(this).addClass('active');
			$(this).siblings().removeClass('active');
			
			var selected_index = $(this).index() + 1;
			$(this).parent().siblings('.tab-content-wrapper').children(':nth-child(' + selected_index + ')').each(function(){
				$(this).siblings().removeClass('active').hide();
				$(this).fadeIn(function(){ $(this).addClass('active'); });
			})
		});		
		
		// paypal form
		jQuery('.gdlr-paypal-form').each(function(){
			var gdlr_form = jQuery(this);
			
			jQuery(this).on('change', 'select[name="quantity"]', function(){
				var total_price = gdlr_form.find('.gdlr-total-price');
				var price = parseFloat(total_price.siblings('.gdlr-price-one').val()) * parseInt(jQuery(this).val());
				total_price.val(price);
			});
			
			jQuery(this).children('.gdlr-button-mail, .gdlr-button-paypal').click(function(){
				var valid = true; 
				var paypal_redirect = true;
				
				if( jQuery(this).hasClass('gdlr-button-paypal') ){
					jQuery(this).siblings('.gdlr-paypal-action').attr('value', 'save_paypal_form');
				}else{
					paypal_redirect = false;
					jQuery(this).siblings('.gdlr-paypal-action').attr('value', 'send_contact_form_mail');
				}
				
				// check require fields
				gdlr_form.find('.gdlr-require').each(function(){
					if( valid && jQuery(this).val() == '' ){
						gdlr_form.children('.gdlr-notice.require-field').slideDown(200)
							.siblings('.gdlr-notice').slideUp(200);
						valid = false;
					}
				});
				
				// check email
				gdlr_form.find('.gdlr-email').each(function(){
					var re = /\S+@\S+/;
					if( valid && !re.test(jQuery(this).val()) ){
						gdlr_form.children('.gdlr-notice.email-invalid').slideDown(200)
							.siblings('.gdlr-notice').slideUp(200);
						valid = false;
					}
				});	

				if( valid ){
					gdlr_form.children('.gdlr-notice').slideUp(200);
					gdlr_form.children('.gdlr-paypal-loader').slideDown(200);
					
					var ajax_url = gdlr_form.attr('data-ajax');
					jQuery.ajax({
						type: 'POST',
						url: ajax_url,
						data: gdlr_form.serialize(),
						dataType: 'json',
						error: function(a, b, c){
							console.log(a, b, c);
						},
						success: function(data){
							gdlr_form.children('.gdlr-notice.alert-message')
								.html(data.message).slideDown(200).addClass('gdlr-' + data.status);
							gdlr_form.children('.gdlr-paypal-loader').slideUp(200);
							
							if( data.status == 'success' && paypal_redirect ){
								gdlr_form.children('[name="invoice"]').val(data.invoice);
								gdlr_form.children('[name="amount"]').val(data.amount);
								gdlr_form[0].submit();
							}else{
								if( data.log ){
									console.log(data.log);
								}
							}
						}
					});					
				}
			});
		});			
		
		// script for session tab item
		$('.gdlr-session-item-head-info').click(function(){
			if( $(this).hasClass('gdlr-active') ) return;
			$(this).siblings().removeClass('gdlr-active');
			$(this).addClass('gdlr-active');
			
			var selected_tab = $(this).attr('data-tab');
			$(this).parent('.gdlr-session-item-head').siblings('.gdlr-session-item-tab-content').hide();
			$(this).parent('.gdlr-session-item-head').siblings('.' + selected_tab).fadeIn();
		});
		
		// script for session counter item
		$('.gdlr-session-counter-item').each(function(){
			var day_field = $(this).find('.gdlr-day');
			var day = parseInt(day_field.text());
			
			var hrs_field = $(this).find('.gdlr-hrs');
			var hrs = parseInt(hrs_field.text());
			
			var min_field = $(this).find('.gdlr-min');
			var min = parseInt(min_field.text());
			
			var sec_field = $(this).find('.gdlr-sec');
			var sec = parseInt(sec_field.text());
			
			var i = setInterval(function(){
				if( sec > 0 ){
					sec--;			
				}else{
					sec = 59;
					if( min > 0 ){
						min--;
					}else{
						min = 59;
						if( hrs > 0 ){
							hrs--;
						}else{
							hrs = 24;
							if( day > 0 ){
								day--;
							}else{
								day = 0;
								hrs = 0;
								min = 0;
								sec = 0;
								clearInterval(i);
							}
							day_field.text(day);
						}
						hrs_field.text(hrs);
					}
					min_field.text(min);
				}
				sec_field.text(sec);	
			}, 1000);
		});
	
		// initiate the tab when the get tab variable is sent
		var inital_tab = $.getUrlVar('tab');
		if( inital_tab ){ $('#' + inital_tab.replace(',', ', #')).each(function(){ $(this).trigger('click'); }); }
		
		// script for code item
		$('.gdlr-code-item .gdlr-code-title').click(function(){
			var parent = $(this).parent();
			if( parent.hasClass('active') ){
				$(this).children('i').removeClass('icon-minus').addClass('icon-plus');
				$(this).siblings('.gdlr-code-content').slideUp(function(){
					parent.removeClass('active');
				});	
			}else{
				$(this).children('i').removeClass('icon-plus').addClass('icon-minus');
				$(this).siblings('.gdlr-code-content').slideDown(function(){
					parent.addClass('active');	
				});				
			}
		});		
		
		// script for parallax background
		$('.gdlr-parallax-wrapper').each(function(){
			if( $(this).hasClass('gdlr-background-image') || $(this).hasClass('gdlr-page-title-wrapper') ){
				var parallax_section = $(this);
				var parallax_speed = parseFloat(parallax_section.attr('data-bgspeed'));
				if( parallax_speed == 0 || gdlr_touch_device ) return;
				if( parallax_speed == -1 ){
					parallax_section.css('background-attachment', 'fixed');
					parallax_section.css('background-position', 'center center');
					return;
				}
					
				$(window).scroll(function(){
					// if in area of interest
					if( ( $(window).scrollTop() + $(window).height() > parallax_section.offset().top ) &&
						( $(window).scrollTop() < parallax_section.offset().top + parallax_section.outerHeight() ) ){
						
						var scroll_pos = 0;
						if( $(window).height() > parallax_section.offset().top ){
							scroll_pos = $(window).scrollTop();
						}else{
							scroll_pos = $(window).scrollTop() + $(window).height() - parallax_section.offset().top;
						}
						parallax_section.css('background-position', 'center ' + (-scroll_pos * parallax_speed) + 'px');
					}
				});			
			}else if( $(this).hasClass('gdlr-background-video') ){
				if(typeof($.fn.mb_YTPlayer) == 'function'){
					$(this).children('.gdlr-bg-player').mb_YTPlayer();
				}
			}else{
				return;
			}
		});	
		
		// runs superfish menu
		if(typeof($.fn.superfish) == 'function'){
			
			// create the mega menu script
			$('#gdlr-main-navigation .sf-mega > ul').each(function(){	
				$(this).children('li').each(function(){
					var current_item = $(this);
					current_item.replaceWith(
						$('<div />').addClass('sf-mega-section')
									.addClass(current_item.attr('data-column'))
									.attr('data-size', current_item.attr('data-size'))
									.html(  $('<div />').addClass('sf-mega-section-inner')
														.addClass(current_item.attr('class'))
														.attr('id', current_item.attr('id'))
														.html(current_item.html())
									)		
					);
				});
				$(this).replaceWith(this.innerHTML);
			});
			
			// make every menu same height
			$('#gdlr-main-navigation .sf-mega').each(function(){
				var sf_mega = $(this); $(this).show();
				
				var row = 0; var column = 0; var max_height = 0;
				sf_mega.children('.sf-mega-section').each(function(){
					if( column % 60 == 0 ){ 
						if( row != 0 ){
							sf_mega.children('[data-row="' + row + '"]').children('.sf-mega-section-inner').height( max_height - 50 );
							max_height = 0;
						}
						row++; $(this).addClass('first-column'); 
					}		
					
					$(this).attr('data-row', row);	
					column += eval('60*' + $(this).attr('data-size'));
				
					if( $(this).height() > max_height ){
						max_height = $(this).height();
					}
				});
				
				sf_mega.children('[data-row="' + row + '"]').children('.sf-mega-section-inner').height( max_height - 50 );		
			});
			
			$('#gdlr-main-navigation').superfish({
				speed: 'fast'
			});		
		}
		
		// responsive menu
		if(typeof($.fn.dlmenu) == 'function'){
			$('#gdlr-responsive-navigation').each(function(){
				$(this).find('.dl-submenu').each(function(){
					if( $(this).siblings('a').attr('href') && $(this).siblings('a').attr('href') != '#' ){
						var parent_nav = $('<li class="menu-item gdlr-parent-menu"></li>');
						parent_nav.append($(this).siblings('a').clone());
						
						$(this).prepend(parent_nav);
					}
				});
				$(this).dlmenu();
			});
		}	
		
		// gallery thumbnail type
		$('.gdlr-gallery-thumbnail').each(function(){
			var thumbnail_container = $(this).children('.gdlr-gallery-thumbnail-container');
		
			$(this).find('.gallery-item').click(function(){
				var selected_slide = thumbnail_container.children('[data-id="' + $(this).attr('data-id') + '"]');
				if(selected_slide.css('display') == 'block') return false;
			
				// check the gallery height
				var image_width = selected_slide.children('img').attr('width');
				var image_ratio = selected_slide.children('img').attr('height') / image_width;
				var temp_height = image_ratio * Math.min(thumbnail_container.width(), image_width);
				
				thumbnail_container.animate({'height': temp_height});
				selected_slide.fadeIn().siblings().hide();
				return false;
			});		

			$(window).resize(function(){ thumbnail_container.css('height', 'auto') });
		});

		// fancybox
		$('a[href$=".jpg"], a[href$=".png"], a[href$=".gif"]').not('[data-rel="fancybox"], [href*="pinterest"]').attr('data-rel', 'fancybox');
		$('[data-rel="fancybox"]').gdlr_fancybox();
		
		// image shortcode 
		$('.gdlr-image-link-shortcode').hover(function(){
			$(this).find('.gdlr-image-link-overlay').animate({opacity: 0.8}, 150);
			$(this).find('.gdlr-image-link-icon').animate({opacity: 1}, 150);
		}, function(){
			$(this).find('.gdlr-image-link-overlay').animate({opacity: 0}, 150);
			$(this).find('.gdlr-image-link-icon').animate({opacity: 0}, 150);
		});	
		
		// Personnel
		$('.gdlr-personnel-item.round-style .personnel-item').each(function(){
			var current_item = $(this);
			function gdlr_set_round_personnel_height(){
				current_item.find('.personnel-item-inner').each(function(){
					$(this).css('margin-top', -($(this).height()/2));
				});
			}
			
			gdlr_set_round_personnel_height();
			$(window).resize(function(){
				gdlr_set_round_personnel_height();
			});
		});
		$('.gdlr-personnel-item.round-style .personnel-item').hover(function(){
			$(this).find('.personnel-author-image').animate({'opacity':0.05}, 200);
			$(this).find('.personnel-item-inner').animate({'opacity':1}, 200);
		}, function(){
			$(this).find('.personnel-author-image').animate({'opacity':1}, 200);
			$(this).find('.personnel-item-inner').animate({'opacity':0}, 200);
		});
		
		// Price Table
		$('.gdlr-price-table-item').each(function(){
			var price_table = $(this);
			
			function set_price_table_height(){
				var max_height = 0;
				var price_content = price_table.find('.price-content');
				
				price_content.css('height', 'auto');
				price_content.each(function(){
					if( max_height < $(this).height() ){ max_height = $(this).height(); }
				});
				price_content.css('height', max_height);
			}
			
			set_price_table_height()
			$(window).resize(function(){ set_price_table_height(); });
		});

		// Default text
		$('form').submit(function(){
			var has_default = false;
			$(this).find('input[data-default]').each(function(){
				if( $(this).is('#url') ){
					if( $(this).val() == $(this).attr('data-default') ) $(this).val('');
				}else{
					if( $(this).val() == $(this).attr('data-default') ) has_default = true;
				}
			});
			
			if(has_default) return false;
		});	
		
		// Search option
		$('#gdlr-menu-search-button').click(function(){
			$(this).siblings('#gdlr-menu-search').slideToggle(200);
		});
		$('.search-text input[data-default], .gdlr-comments-area input[data-default]').each(function(){
			var default_value = $(this).attr("data-default");
			$(this).val(default_value);
			$(this).live("blur", function(){
				if ($(this).val() == ""){
					$(this).val(default_value);
				}	
			}).live("focus", function(){
				if ($(this).val() == default_value){
					$(this).val("");
				}
			});		
		});		

		// smooth anchor
		if( window.location.hash ){
			$('html, body').animate({
				scrollTop: $(window.location.hash).offset().top - 68
			}, 500);
		}
		$('.gdlr-navigation a[href*="#"], .gdlr-responsive-navigation a[href*="#"]').click(function(){
			if( $(this).attr('href').length > 1 ){
				var item_id = $(this.hash);
				
				if( $('body').hasClass('home') ){
					if( item_id.length > 0 ){
						$('html, body').animate({
							scrollTop: item_id.offset().top - $('.gdlr-fixed-header').height()
						}, 500);
						return false;
					}
				}else{
					window.location.replace($('.body-wrapper').attr('data-home') + '/' + this.hash);
				}
			}
		});	
		
		// animate ux
		if( !gdlr_touch_device && ( !$.browser.msie || (parseInt($.browser.version) > 8)) ){
		
			// image ux
			$('.content-wrapper img').each(function(){
				if( $(this).closest('.gdlr-ux, .ls-wp-container, .product, .flexslider, .nivoSlider').length ) return;
				
				var ux_item = $(this);
				if( ux_item.offset().top > $(window).scrollTop() + $(window).height() ){
					ux_item.css({ 'opacity':0 });
				}else{ return; }
				
				$(window).scroll(function(){
					if( $(window).scrollTop() + $(window).height() > ux_item.offset().top + 100 ){
						ux_item.animate({ 'opacity':1 }, 1200); 
					}
				});					
			});
		
			// item ux
			$('.gdlr-ux').each(function(){
				var ux_item = $(this);
				if( ux_item.hasClass('gdlr-chart') || ux_item.hasClass('gdlr-skill-bar') ){
					if( ux_item.offset().top < $(window).scrollTop() + $(window).height() ){
						if( ux_item.hasClass('gdlr-chart') && (!$.browser.msie || (parseInt($.browser.version) > 8)) ){
							ux_item.gdlr_pie_chart();
						}else if( ux_item.hasClass('gdlr-skill-bar') ){
							ux_item.children('.gdlr-skill-bar-progress').each(function(){
								if($(this).attr('data-percent')){
									$(this).animate({width: $(this).attr('data-percent') + '%'}, 1200, 'easeOutQuart');
								}
							});	
						}
						return;
					}
				}else if( ux_item.offset().top > $(window).scrollTop() + $(window).height() ){
					ux_item.css({ 'opacity':0, 'padding-top':20, 'margin-bottom':-20 });
				}else{ return; }	

				$(window).scroll(function(){
					if( $(window).scrollTop() + $(window).height() > ux_item.offset().top + 100 ){
						if( ux_item.hasClass('gdlr-chart') && (!$.browser.msie || (parseInt($.browser.version) > 8)) ){
							ux_item.gdlr_pie_chart();
						}else if( ux_item.hasClass('gdlr-skill-bar') ){
							ux_item.children('.gdlr-skill-bar-progress').each(function(){
								if($(this).attr('data-percent')){
									$(this).animate({width: $(this).attr('data-percent') + '%'}, 1200, 'easeOutQuart');
								}
							});	
						}else{
							ux_item.animate({ 'opacity':1, 'padding-top':0, 'margin-bottom':0 }, 1200);
						}
					}
				});					
			});
			
		// do not animate on scroll in mobile
		}else{
		
			// Pie chart
			if(!$.browser.msie || (parseInt($.browser.version) > 8)){
				$('.gdlr-chart').gdlr_pie_chart();
			}	

		
			// skill bar
			$('.gdlr-skill-bar-progress').each(function(){
				if($(this).attr('data-percent')){
					$(this).animate({width: $(this).attr('data-percent') + '%'}, 1200, 'easeOutQuart');
				}
			});			
		}		

		// runs nivoslider when available
		$('.nivoSlider').gdlr_nivoslider();		
		
		// runs flexslider when available
		$('.flexslider').gdlr_flexslider();
		
	});
	
	$(window).load(function(){

		// run isotope when available
		$('.gdlr-isotope').gdlr_isotope();	
		
		// run pie chart for ie8 and below
		if($.browser.msie && (parseInt($.browser.version) <= 8)){
			$('.gdlr-chart').gdlr_pie_chart();
		}	

		// sliding nav
		if( !gdlr_touch_device ){
			var slide_nav = $('#gdlr-navigation-gimmick');
			var current_pos = 0;
			var current_menu_width = 0;
				
			
			// init menu width
			$('#gdlr-main-navigation > ul > li.current-menu-item, #gdlr-main-navigation > ul > li.current-menu-ancestor, #gdlr-main-navigation > ul > li.current_page_item, #gdlr-main-navigation > ul > li.current_page_ancestor').each(function(){
				var padding = parseInt( $(this).css('padding-right') );
				current_pos = $(this).position().left + padding;
				current_menu_width = $(this).width();

				slide_nav.css({'width': current_menu_width, 'left': current_pos});
			});
			if( current_pos == 0 ){ 
				current_pos = $('#gdlr-main-navigation').position().left; 
				slide_nav.css('left', current_pos);
			}
			
			$('.gdlr-navigation a[href*="#"], .gdlr-responsive-navigation a[href*="#"]').click(function(){
				var padding = parseInt( $(this).parent().css('padding-left') );
				current_pos = $(this).parent().position().left + padding;
				current_menu_width = $(this).parent().width();
			});

			$(window).resize(function(){ 
				// init menu width
				$('#gdlr-main-navigation > ul > li.current-menu-item, #gdlr-main-navigation > ul > li.current-menu-ancestor, #gdlr-main-navigation > ul > li.current_page_item, #gdlr-main-navigation > ul > li.current_page_ancestor').each(function(){
					var padding = parseInt( $(this).css('padding-left') );
					current_pos = $(this).position().left + padding;
					current_menu_width = $(this).width();

					slide_nav.css({'width': current_menu_width, 'left': current_pos});
				});
				if( current_pos == 0 ){ 
					current_pos = $('#gdlr-main-navigation').position().left; 
					slide_nav.css('left', current_pos);
				}
			});
				
			$('#gdlr-main-navigation > ul > li').hover(function(){
				var padding = parseInt( $(this).css('padding-left') );
			
				slide_nav.animate({ 'width': jQuery(this).width(), 'left': jQuery(this).position().left + padding}, 
					{ queue: false, easing: 'easeOutQuad', duration: 250 });			
			}, function(){
				slide_nav.animate({ 'width': current_menu_width, 'left': current_pos }, 
					{ queue: false, easing: 'easeOutQuad', duration: 250 });		
			});	
		}				
		
		// float menu
		$('.body-wrapper.float-menu').each(function(){
			var sub_area = $('#gdlr-header-substitute');
			var main_area = sub_area.siblings('.gdlr-header-wrapper');
			
			var logo = main_area.find('.gdlr-logo');
			var logo_img = main_area.find('.gdlr-logo img');
			var navigation = main_area.find('.gdlr-navigation-wrapper');				
			var original = {
				logo_top: logo.css('margin-top'), 
				logo_bottom: logo.css('margin-bottom'), 
				nav_top: navigation.css('margin-top')
			};
				
			$(window).scroll(function(){
				if( main_area.hasClass('gdlr-fixed-header') && ($(this).scrollTop() == 0 || $(this).width() < 959)){
					main_area.children('.top-navigation-wrapper').slideDown(100);
					
					logo.animate({'margin-top': original.logo_top, 'margin-bottom': original.logo_bottom}, {duration: 100, queue: false});
					logo_img.animate({'width': '100%'}, {duration: 100, queue: false, complete: function(){
						main_area.removeClass('gdlr-fixed-header');
						sub_area.css('height', 'auto');
					}});
					navigation.animate({'margin-top': original.nav_top}, {duration: 100, queue: false});								
				}else if( !main_area.hasClass('gdlr-fixed-header') && $(this).width() > 959 &&
					$(this).scrollTop() > main_area.children('.gdlr-header-inner').offset().top - parseInt($('html').css('margin-top')) ){
						
						sub_area.css('height', main_area.height());
						
						main_area.addClass('gdlr-fixed-header');
						main_area.children('.top-navigation-wrapper').hide();

						logo.animate({'margin-top': '20', 'margin-bottom': '23'}, {duration: 100, queue: false});
						logo_img.animate({'width': '80%'}, {duration: 0, queue: false});
						navigation.animate({'margin-top': '21'}, {duration: 100, queue: false});
				}				
			});
		});			
		
		$(window).trigger('resize');
		$(window).trigger('scroll');
	});

})(jQuery);