import createDisplayConditions from "src/decidim/forms/display_conditions.component";

describe("DisplayConditionsComponent (Decidim 0.28 + clearInputValues)", () => {
  beforeEach(() => {
    document.body.innerHTML = `
      <form class="answer-questionnaire">
        <div class="question" data-question-id="2396">
          <div class="answer-questionnaire__single-option js-radio-button-collection">
            <div class="js-collection-input">
              <input type="radio" name="questionnaire[responses][0][choices][][body]" id="q1_yes" value="Sì" />
              <input type="hidden" name="questionnaire[responses][0][choices][][answer_option_id]" value="6180" disabled />
            </div>
            <div class="js-collection-input">
              <input type="radio" name="questionnaire[responses][0][choices][][body]" id="q1_no" value="No" />
              <input type="hidden" name="questionnaire[responses][0][choices][][answer_option_id]" value="6181" disabled />
            </div>
          </div>
        </div>

        <div class="answer question" data-conditioned="true" data-question-id="2397">
          <div class="display-condition" data-id="1397" data-type="equal" data-condition="2396" data-option="6180" data-mandatory="true"></div>
          <div class="js-radio-button-collection">
            <div class="js-collection-input">
              <input type="radio" name="questionnaire[responses][1][choices][][body]" id="q2_opt" value="Opzione A" />
              <input type="hidden" name="questionnaire[responses][1][choices][][answer_option_id]" value="7001" />
            </div>
          </div>
          <input type="text" name="questionnaire[responses][1][body]" id="q2_text" value="" />
        </div>
      </form>
    `;

    createDisplayConditions({
      wrapperField: $(".question[data-question-id='2397']")
    });
  });

  test("nasconde la domanda figlia al caricamento e la mostra solo quando si seleziona l'opzione 'equal'", () => {
    const $q2 = $(".question[data-question-id='2397']");

    expect($q2.css("display")).toBe("none");
    expect($("#q2_opt").prop("disabled")).toBe(true);

    // Seleziona "Sì" (id 6180)
    $("#q1_yes").prop("checked", true).trigger("change");

    expect($q2.css("display")).not.toBe("none");
    expect($("#q2_opt").prop("disabled")).toBe(false);
    expect($("#q2_text").prop("disabled")).toBe(false);
  });

  test("svuota i valori e scatena 'change' (per LocalStorage) quando la condizione torna falsa", () => {
    const $q2 = $(".question[data-question-id='2397']");
    const changeSpy = jest.fn();

    $("#q2_opt, #q2_text").on("change", changeSpy);

    // Mostra la domanda 2 e compila sia radio che testo
    $("#q1_yes").prop("checked", true).trigger("change");
    $("#q2_opt").prop("checked", true);
    $("#q2_text").val("Testo inserito");

    // Cambia su "No" (id 6181): la domanda 2 si nasconde e deve pulire i campi
    $("#q1_no").prop("checked", true).trigger("change");

    expect($q2.css("display")).toBe("none");
    expect($("#q2_opt").is(":checked")).toBe(false);
    expect($("#q2_text").val()).toBe("");
    expect($("#q2_opt").prop("disabled")).toBe(true);
    expect(changeSpy).toHaveBeenCalledTimes(2);
  });
});
