/* eslint-disable require-jsdoc */

class OptionAttachedInputsComponent {
  constructor(options = {}) {
    this.wrapperField = options.wrapperField;
    this.controllerFieldSelector = options.controllerFieldSelector;
    this.dependentInputSelector = options.dependentInputSelector;
    this.controllerSelector = this.wrapperField.find(this.controllerFieldSelector);
    this._bindEvent();
    this._run();
  }

  _run() {
    this.controllerSelector.each((idx, el) => {
      const $field = $(el);
      const enabled = $field.is(":checked");

      $field.parents("div.collection-input").find(this.dependentInputSelector).prop("disabled", !enabled);
    });
  }

  _bindEvent() {
    this.controllerSelector.on("change", (event) => {
      this._run();

      /* validation of checks */
      let src_el = event.target;
      let question_label = $(src_el).closest('div[data-question-id]').children('.questionnaire-question');
      if ($(question_label).text().search(/\*$/) >= 0){ /*It is a mandatory checkbox*/
        if ($(src_el).is(':checked')){ /* Check action */
          removeError(question_label);
        }
        else if (! $(src_el).is(':checked')){ /* Uncheck action */
          if ($(src_el).parents('.check-box-collection').find('input[type="checkbox"]:checked').length == 0){
            showError(question_label, 'VALIDAZIONE LATO CLIENT: La domanda necessita di almeno una selezione obbligatoria');
          }
        }
      }

      /* Remove error from tos when checked */
      $('input#questionnaire_tos_agreement').on("change", (event) => {
        let src_el = event.target;
        if ($(src_el).is(':checked')){
          removeError($(src_el).parent());
        }
      });
    });

    $(document).on("submit", "form", (event) => {
      var errors = false;
	  
      /* Validate checkboxs */
      $('.check-box-collection').each((idx, rbc) => {
        let question_label = $(rbc).siblings('.questionnaire-question');
		console.debug("checkbox rbc=" + $(rbc).value + " idx=" + $(idx).value);
		if ($(question_label).text().search(/\*$/) >= 0){ /*It is a mandatory checkbox*/
          if ($(rbc).find('input[type="checkbox"]:checked').length == 0){
            showError(question_label, 'VALIDAZIONE LATO CLIENT (CB SCELTA MULTIPLA): La domanda necessita di almeno una selezione obbligatoria');
            errors = true;
          }
        }
      });
	  
	  /* Validate matrix with checkbox */
	  $('.check-box-collection').find('.collection-input').each((idx, rbc) => { 
		let question_label = $(rbc).siblings('.questionnaire-question');
		console.debug("checkbox rbc=" + $(rbc).value + "idx=" + $(idx).value);
		if ($(rbc).find('input[type="checkbox"]:checked').length == 0){
		  showError(question_label, 'VALIDAZIONE LATO CLIENT (MATRICE SCELTA MULTIPLA): La domanda necessita di almeno una selezione obbligatoria');
		  errors = true;
		}
	  });

      /* Validate radios */
      $('.radio-button-collection').each((idx, rbc) => {
        let question_label = $(rbc).siblings('.questionnaire-question');
		console.debug("radiobutton rbc=" + $(rbc).value + " idx=" + $(idx).value);
        if ($(question_label).text().search(/\*$/) >= 0){ /*It is a mandatory checkbox*/          
		 if ($(rbc).find('input[type="radio"]:checked').length == 0){
            showError(question_label, 'VALIDAZIONE LATO CLIENT (RB SCELTA SINGOLA): La domanda necessita di almeno una selezione obbligatoria');
            errors = true;
         }
        }
      });
	  
	  /* Validate matrix with radios*/
	  $('.radio-button-collection').find('.collection-input').each((idx, rbc) => { 
		 let question_label = $(rbc).siblings('.questionnaire-question');
		 console.debug("radio rbc=" + $(rbc).value + "idx=" + $(idx).value);
		 if ($(rbc).find('input[type="radio"]:checked').length == 0){
		  showError(question_label, 'VALIDAZIONE LATO CLIENT (MATRICE SCELTA SINGOLA): La domanda necessita di almeno una selezione obbligatoria');
		  errors = true;
	     }
	  }); 

      /* Validate tos */
      let tos = $('input#questionnaire_tos_agreement');
      if (! $(tos).is(':checked')){
        showError($(tos).parent(), 'I termini e le condizioni d\'uso devono esssere accettate');
        errors = true;
      }

      if (errors){
        event.preventDefault();
        var alert = $('.flash.callout.alert');
        if (! alert.length){
          $('#content').prepend('<div class="flash callout alert" role="alert" aria-atomic="true" data-closable="" tabindex="0">Votre réponse à l\'enquête comporte des erreurs.<button name="button" type="button" class="close-button" data-close="" aria-label="Rejeter la notification"><span aria-hidden="true">×</span></button>&nbsp;</div>');
        } else if (alert.attr('style')){
          alert.removeAttr('style');
        }        
      }

      window.exitUrl = event.currentTarget.action;
    });
  }
}

function showError(label, msg){
  $(label).addClass('is-invalid-label');
  $(label).parent().children('[role=alert]').remove();
  $(label).parent().append('<small class="form-error is-visible" role="alert">' + msg + '</small>');
}

function removeError(label){
  $(label).removeClass('is-invalid-label');
  $(label).parent().children('[role=alert]').remove();
}

export default function createOptionAttachedInputs(options) {
  return new OptionAttachedInputsComponent(options);
}