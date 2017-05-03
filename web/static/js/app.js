// Brunch automatically concatenates all files in your
// watched paths. Those paths can be configured at
// config.paths.watched in "brunch-config.js".
//
// However, those files will only be executed if
// explicitly imported. The only exception are files
// in vendor, which are never wrapped in imports and
// therefore are always executed.

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
import "phoenix_html"

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

// import socket from "./socket"


function attach() {
    const token = document.querySelector("meta[name='_csrf']").content;

    console.log(token);

    const opts = {
        method: 'PUT',
        headers: {'x-csrf-token' : token},
        credentials: 'same-origin'
    };

    const elements = document.getElementsByClassName("setting");
    for (var i = 0; i < elements.length; i++) {
        const el = elements.item(i);
        el.addEventListener("change", e => {
            const el  = e.target;
            const key = el.name;
            const val = el.options[el.selectedIndex].value;
            console.log(`key: ${key} value: ${val}`);

            fetch(`/user?${key}=${val}`, opts)
            .then(resp => {
                console.log(resp);
            });
        });
    }
}


if (document.readyState === 'complete' || document.readyState !== 'loading') {
    attach();
} else {
    attach();
}
