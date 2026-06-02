const params = new URLSearchParams(window.location.search);
const page = sanitize(params.get("page") || "start");
const archive = sanitize(params.get("archive") || "");
const blog = sanitize(params.get("archive") || "");

let archiveData = null;

init();

// in function to allow await on data, before calling functions that use said data
async function init() {
  await loadData();

  if (archive) {
    showArchive(archive);
  } else {
    loadPage(page);
  }
}

// all global data loaded here
async function loadData() {
  archiveData = await fetchJson("/data/archive.json");
}

// allow only a-z, A-Z, 0-9 and . in strings
function sanitize(str) {
  return str?.replace(/[^a-zA-Z0-9/.]/g, "");
}

// format iso dates from json to "May 29, 2023" format
function formatIsoDate(str) {
  const d = new Date(str);
  const o = {
    year: "numeric",
    month: "long",
    day: "numeric",
  };

  return d.toLocaleDateString("en-US", o);
}

function toggleMenu() {
  var menu = document.getElementById("mobilemenu");
  menu.classList.toggle("w3-show");
}

function errorPage(title, message) {
  return `
    <div class="w3-row-padding darkcolor w3-padding-32 w3-container w3-center">
      <div class="w3-content">
        <h1>${title}</h1>
        <p>${message}</p>
        <p><a href="/">Go to the homepage</a></p>
      </div>
    </div>`;
}

async function loadPage(file) {
  await fetchContentAndMeta(`/pages/${file}.html`).then(
    ({ metadata, content }) => {
      document.getElementById("contentContainer").innerHTML = content;

      if (metadata.title) {
        document.title = metadata.title + " - " + document.title;
      }
    },
  );
}

async function showArchive(version) {
  console.log(`showArchive requested for ${version}`);

  //Load the archive page, so it displays before the current version we show
  await loadPage("archive");

  //Add available versions to version dropdown
  const archiveList = document.getElementById("archivelist");
  archiveData.versions.forEach((v) => {
    let listItem = document.createElement("a");
    listItem.href = `/?archive=${v.id}`;
    listItem.innerText = v.title;
    listItem.classList.add("w3-bar-item", "w3-button");
    archiveList.appendChild(listItem);
  });

  //Load the desired version into subContentContainer
  container = document.getElementById("subContentContainer");
  const versionInfo = archiveData.versions.find((v) => v.id === version);

  if (!versionInfo) {
    console.error(`Archive version with id ${version} not found`);
    return;
  }

  if (versionInfo.title) {
    document.title = versionInfo.title + " - " + document.title;
  }

  if (versionInfo.unavailable) {
    console.log(
      `Version with id ${version} does not have screenshot or download`,
    );
  }

  let html = `
      <div class="w3-center" id="version">
        <h2>Version ${versionInfo.title}</h2>
        <div class="posttime">
          Released <time datetime="${versionInfo.date}">${formatIsoDate(versionInfo.date)}</time><br>
          &nbsp;</div>`;

  if (!versionInfo.unavailable) {
    html += `<a href="/img/archive/${version}.png">
          <img src="/img/archive/${version}.png" alt="Screenshot of Costa ${versionInfo.title}">
        </a>`;
  }

  html += `</div>
  <p>${versionInfo.description}</p>`;
  container.innerHTML = html;

  const ul = document.createElement("ul");
  versionInfo.bullets.forEach((text) => {
    const li = document.createElement("li");
    li.textContent = text;
    ul.appendChild(li);
  });
  container.appendChild(ul);

  if (!versionInfo.unavailable) {
    const downloadBtn = document.createElement("div");
    downloadBtn.classList.add("w3-center");
    downloadBtn.innerHTML = `
        <a class="w3-button" href="downloads/costa${version}.zip">
				<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-floppy2-fill" viewBox="0 0 16 16">
					<path d="M12 2h-2v3h2z"></path>
					<path d="M1.5 0A1.5 1.5 0 0 0 0 1.5v13A1.5 1.5 0 0 0 1.5 16h13a1.5 1.5 0 0 0 1.5-1.5V2.914a1.5 1.5 0 0 0-.44-1.06L14.147.439A1.5 1.5 0 0 0 13.086 0zM4 6a1 1 0 0 1-1-1V1h10v4a1 1 0 0 1-1 1zM3 9h10a1 1 0 0 1 1 1v5H2v-5a1 1 0 0 1 1-1"></path>
				</svg>
				Download Costa ${versionInfo.title}
			</a>
		`;
    container.appendChild(downloadBtn);
  }

  document
    .getElementById("subContentContainer")
    .parentElement.classList.remove("w3-hide");
}

async function fetchContentAndMeta(file) {
  console.info(`Loading content and metadata from ${file}`);

  try {
    let metadata;
    let content;
    const response = await fetch(file);

    if (!response.ok) {
      metadata = { title: "Page not found" };
      content = errorPage(
        "Page not found",
        `It seems you have followed a link to a page that doesn't exist.`,
      );
      return { metadata, content };
    }

    const raw = await response.text();
    const wrapper = document.createElement("div");
    wrapper.innerHTML = raw;

    // --- Metadata ---
    const metaTag = wrapper.querySelector("#meta");
    if (metaTag) {
      metadata = JSON.parse(metaTag.textContent);
    } else {
      console.warn(`Missing #meta block in ${file}`);
      metadata = "";
    }

    // --- Content ---
    const contentTag = wrapper.querySelector("#content");
    if (contentTag) {
      content = contentTag.innerHTML;
    } else {
      console.warn(`Missing #content block in ${file}`);
      content = "No content.";
    }

    return { metadata, content };
  } catch (err) {
    console.error(err.message);
    metadata = { title: "Error" };
    content = errorPage(
      "Error",
      `An error occurred while loading the content you requested: ${err.message}`,
    );
    return { metadata, content };
  }
}

async function fetchJson(file) {
  console.info(`Loading JSON from ${file}`);

  try {
    const response = await fetch(file);

    if (!response.ok) {
      console.error(
        `Got http ${response.status} ${response.statusText} fetching ${file}`,
      );
      return { error: { code: response.status, message: response.statusText } };
    }

    const json = await response.text();
    const obj = JSON.parse(json);

    return obj;
  } catch (err) {
    console.error(`Error ${err.code} - ${err.message}`);
    return { error: { code: response.status, message: response.statusText } };
  }
}
