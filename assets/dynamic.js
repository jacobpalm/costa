let siteData = null;
let versionList = null;

init();

// in function to allow await on data, before calling functions that use said data
async function init() {
  await loadData();
  versionList = document.getElementById("versionList");
  if (siteData.versions) {
    populateVersionList();
    showVersion();
  }
  showScreenshots();
}

// all global data loaded here
async function loadData() {
  siteData = await fetchJson("/data/data.json");
  if (siteData) {
    siteData.versions.sort((a, b) => Number(b.id) - Number(a.id));
  }
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
  let i = 0;
  siteData.versions.forEach((v) => {
    let listItem = document.createElement("option");
    listItem.value = v.id;
    listItem.innerText = v.title;
    i++;
    if (i == 1) {
      listItem.innerText += " (current)";
    }
    versionList.appendChild(listItem);
  });
}

async function showVersion() {
  try {
    const version = versionList.value;
    if (!version) {
      throw new Error("Could not get value of versionList");
    }

    //Load the desired version
    const versionInfo = siteData.versions.find((v) => v.id === version);
    if (!versionInfo) {
      throw new Error(`Version with id ${version} not found`);
    }

    const template = document.getElementById("versionTemplate");
    if (!template) {
      throw new Error("Version template not found");
    }

    const clone = template.content.cloneNode(true);
    clone.querySelector("#title").textContent = "Version " + versionInfo.title;
    clone.querySelector("#date").textContent = formatIsoDate(versionInfo.date);
    clone.querySelector("#description").innerHTML = versionInfo.description;

    if (versionInfo.unavailable) {
      // No screenshot or download link for this version
      clone.querySelector("#downloadlink").remove();
      clone.querySelector("#imagelink").remove();
    } else {
      clone.querySelector("#downloadlink").href =
        `/downloads/costa${versionInfo.id}.zip`;
      clone.querySelector("#downloadtext").innerText =
        `Download Costa ${versionInfo.title}`;
      clone.querySelector("#imagelink").href = `/img/${versionInfo.id}.png`;
      clone.querySelector("#image").src = `/img/${versionInfo.id}.png`;
      clone.querySelector("#image").alt += versionInfo.title;
    }

    // loop through and add each bullet to to ol
    versionInfo.bullets.forEach((text) => {
      const li = document.createElement("li");
      li.textContent = text;
      clone.querySelector("#bullets").appendChild(li);
    });
    document.querySelector("#versionDetails").innerHTML = "";
    document.querySelector("#versionDetails").appendChild(clone);
  } catch (e) {
    console.error(e.message);
    const versionDetails = document.querySelector("#versionDetails");
    if (versionDetails) {
      versionDetails.innerHTML = `<p>An error occured while loading details about this version:<br />${e.message}`;
    }
  }
}

function showScreenshots() {
  const screenshots = document.querySelector("#screenshots");
  if (!screenshots) {
    console.error("Could not find screenshots element");
    return;
  }

  try {
    if (!siteData.screenshots || siteData.screenshots.length == 0) {
      throw new Error("Site data doesn't contain any screenshots");
    }

    siteData.screenshots.forEach((imgData) => {
      const img = document.createElement("img");
      const a = document.createElement("a");
      a.href = imgData.src;
      a.appendChild(img);
      img.src = imgData.src;
      img.alt = imgData.alt;
      screenshots.appendChild(a);
    });
  } catch (e) {
    console.error(e.message);
    screenshots.innerHTML = `<p>An error occured while loading screenshots:<br />${e.message}</p>`;
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
