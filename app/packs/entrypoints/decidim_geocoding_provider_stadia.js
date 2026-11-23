import "src/decidim/geocoding"

$(() => {
  $("[data-decidim-geocoding]").each((_i, el) => {
    const $input = $(el);
    const config = $input.data("decidim-geocoding");
    const apiKey = config?.api_key || config?.apiKey;
    const queryMinLength = config?.query_min_length || config?.queryMinLength || 2;
    const language = $("html").attr("lang");
    let currentSuggestionQuery = null;

    if (!config || !config.url || config.url.length < 1) {
      return;
    }

    $input.on("geocoder-suggest.decidim", (_ev, query, callback) => {
      clearTimeout(currentSuggestionQuery);

      if (`${query}`.trim().length < queryMinLength) {
        callback([]);
        return;
      }

      currentSuggestionQuery = setTimeout(() => {
        const params = new URLSearchParams({ text: query });
        if (apiKey) {
          params.append("api_key", apiKey);
        }
        if (language) {
          params.append("lang", language);
        }

        fetch(`${config.url}?${params.toString()}`)
          .then(async (response) => {
            if (!response.ok) {
              const body = await response.text();
              throw new Error(`Stadia Autocomplete HTTP ${response.status}: ${body}`);
            }
            return response.json();
          })
          .then((data) => {
            if (!data || !Array.isArray(data.features)) {
              callback([]);
              return;
            }

            const results = data.features.map((item) => {
              const label = item.properties.label;
              const [lng, lat] = item.geometry.coordinates;

              return {
                key: label,
                value: label,
                coordinates: [lat, lng]
              };
            });

            callback(results);
          })
          .catch((err) => {
            console.error("[Decidim Stadia Autocomplete]", err);
            callback([]);
          });
      }, 200);
    });
  });
});