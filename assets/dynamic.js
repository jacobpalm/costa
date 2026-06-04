let siteData = null;
let versionList = null;

init();

// in function to allow await on data, before calling functions that use said data
async function init() {
  await loadData();
  versionList = document.getElementById("versionList");
  if (siteData.versions) {
    populateVersionList();
    showVersion(siteData.versions[0]);
  }
  if (siteData.screenshots) {
    showScreenshots();
  }
}

// all global data loaded here
async function loadData() {
  siteData = await fetchJson("/data/data.json");
  if (siteData) {
    siteData.versions.sort((a, b) => Number(b.id) - Number(a.id));
  }
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

async function populateVersionList() {
  //Add available versions to version dropdown
  if (!versionList) {
    console.error(`populateVersionList called with no argument`);
    return;
  }
  siteData.versions.forEach((v) => {
    let listItem = document.createElement("option");
    listItem.value = v.id;
    listItem.innerText = v.title;
    versionList.appendChild(listItem);
  });
}

async function showVersion() {
  const version = versionList.value;

  console.log(`showVersion requested for ${version}`);
  if (!version) {
    return;
  }

  //Load the desired version into subContentContainer
  const versionInfo = siteData.versions.find((v) => v.id === version);

  if (!versionInfo) {
    console.error(`Version with id ${version} not found`);
    return;
  }

  if (versionInfo.unavailable) {
    console.log(
      `Version with id ${version} does not have screenshot or download`,
    );
  }

  const versionHeader = document.getElementById("versionHeader");
  const versionDate = document.getElementById("versionDate");
  const versionImgLink = document.getElementById("versionImgLink");
  const versionImg = document.getElementById("versionImg");
  const versionDescription = document.getElementById("versionDescription");
  const versionBullets = document.getElementById("versionBullets");
  const downloadButton = document.getElementById("downloadButton");
  const downloadText = document.getElementById("downloadText");

  versionHeader.innerText = `Version ${versionInfo.title}`;
  versionDate.datetime = versionInfo.date;
  versionDate.innerText = formatIsoDate(versionInfo.date);

  if (!versionInfo.unavailable) {
    versionImgLink.classList.remove("hide");
    versionImgLink.href = `/img/${versionInfo.id}.png`;
    versionImg.src = versionImgLink.href;
  } else {
    versionImg.classList.add("hide");
  }

  versionDescription.innerHTML = versionInfo.description;

  versionBullets.innerHTML = "";
  versionInfo.bullets.forEach((text) => {
    const li = document.createElement("li");
    li.textContent = text;
    versionBullets.appendChild(li);
  });

  if (!versionInfo.unavailable) {
    downloadButton.classList.remove("hide");
    downloadButton.href = `/downloads/costa${versionInfo.id}.zip`;
    downloadText.innerText = `Download Costa ${versionInfo.title}`;
  } else {
    downloadButton.classList.add("hide");
  }
}

function showScreenshots() {
  const screenshots = document.getElementById("screenshots");

  siteData.screenshots.forEach((imgData) => {
    const img = document.createElement("img");
    const a = document.createElement("a");
    a.href = imgData.src;
    a.appendChild(img);
    img.src = imgData.src;
    img.alt = imgData.alt;
    screenshots.appendChild(a);
  });
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
