import "src/decidim/geocoding"

$(() => {
  $("[data-decidim-geocoding]").each((_i, el) => {
    const $input = $(el);
    const config = $input.data("decidim-geocoding");
    const queryMinLength = config?.queryMinLength || 2;
    const language = $("html").attr("lang");
    let currentSuggestionQuery = null;

    if (!config || !config.url || config.url.length < 1) {
      return;
    }

    $input.on("geocoder-suggest.decidim", (_ev, query, callback) => {
      clearTimeout(currentSuggestionQuery);

      if (`${query}`.trim().length < queryMinLength) {
        return;
      }

      currentSuggestionQuery = setTimeout(() => {
        const params = new URLSearchParams({ text: query });
        if (config.apiKey) {
          params.append("api_key", config.apiKey);
        }
        if (language) {
          params.append("lang", language);
        }

        fetch(`${config.url}?${params.toString()}`)
          .then((response) => response.json())
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
          .catch(() => callback([]));
      }, 200);
    });
  });
});