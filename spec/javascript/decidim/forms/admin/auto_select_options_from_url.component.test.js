import AutoSelectOptionsFromUrl from "src/decidim/forms/admin/auto_select_options_from_url.component";

describe("AutoSelectOptionsFromUrl", () => {
  afterEach(() => {
    jest.restoreAllMocks();
  });

  test("rimuove la query string da data-url, popola le opzioni e seleziona data-selected", () => {
    document.body.innerHTML = `
      <select id="condition-question" data-url="/admin/surveys/1/answer_options?question_id=999">
        <option value="2396" selected>Domanda 1</option>
        <option value="2398">Domanda 3</option>
      </select>
      <select id="answer-option" data-selected="6181">
        <option value="">Seleziona opzione</option>
        <option value="old">Vecchia opzione</option>
      </select>
    `;

    const getJsonSpy = jest.spyOn($, "getJSON").mockImplementation((url, params, callback) => {
      callback([
        { id: 6180, body: "Sì" },
        { id: 6181, body: "No" }
      ]);
    });

    new AutoSelectOptionsFromUrl({
      source: $("#condition-question"),
      select: $("#answer-option"),
      sourceToParams: ($el) => ({ question_id: $el.val() })
    });

    // Verifica chiamata iniziale con URL pulito (senza ?question_id=999)
    expect(getJsonSpy).toHaveBeenCalledWith(
      "/admin/surveys/1/answer_options",
      { question_id: "2396" },
      expect.any(Function)
    );

    const options = $("#answer-option option").map((_, el) => ({
      value: el.value,
      text: el.textContent
    })).get();

    expect(options).toEqual([
      { value: "", text: "Seleziona opzione" },
      { value: "6180", text: "Sì" },
      { value: "6181", text: "No" }
    ]);
    expect($("#answer-option").val()).toBe("6181");

    // Verifica cambio domanda sorgente
    $("#condition-question").val("2398").trigger("change");
    expect(getJsonSpy).toHaveBeenLastCalledWith(
      "/admin/surveys/1/answer_options",
      { question_id: "2398" },
      expect.any(Function)
    );
  });

  test("non solleva eccezioni se data-url non è valorizzato", () => {
    document.body.innerHTML = `
      <select id="condition-question"><option value="2396">Domanda 1</option></select>
      <select id="answer-option"><option value="">Seleziona</option></select>
    `;

    const getJsonSpy = jest.spyOn($, "getJSON").mockImplementation(() => {});

    expect(() => {
      new AutoSelectOptionsFromUrl({
        source: $("#condition-question"),
        select: $("#answer-option"),
        sourceToParams: ($el) => ({ question_id: $el.val() })
      });
    }).not.toThrow();

    expect(getJsonSpy).toHaveBeenCalledWith("", { question_id: "2396" }, expect.any(Function));
  });
});
