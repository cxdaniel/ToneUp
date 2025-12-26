'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter_bootstrap.js": "9f6774b3a2b377afbfd20e4625f4e639",
"version.json": "bb8451b95f0a463336fae7d89eab4e28",
"index.html": "32a0d0dd00334dd22c3cd2e5692e63a7",
"/": "32a0d0dd00334dd22c3cd2e5692e63a7",
"main.dart.js": "1498e805a80ce503726bcfd3731ab761",
"flutter.js": "888483df48293866f9f41d3d9274a779",
"_redirects": "c88cd99565abac3edd2f1844ffab5993",
"favicon.png": "db6fd639e319fbd2655e67ae1b270b6d",
"main.dart.mjs": "0b39ebd7c46350144acdc04da4e3b700",
"icons/Icon-192.png": "39d5eb22a9de26f56f79d58c783526b6",
"icons/Icon-maskable-192.png": "39d5eb22a9de26f56f79d58c783526b6",
"icons/Icon-maskable-512.png": "144654685e4b7fafdb85026b80cedf46",
"icons/Icon-512.png": "144654685e4b7fafdb85026b80cedf46",
"manifest.json": "feb12cbb413851d5721e49c9d821de14",
"main.dart.wasm": "4b25a3cd69a7e87bb30ee4823ebd36a1",
"assets/AssetManifest.json": "c564ba88760c2099dbe008eca8bc378a",
"assets/NOTICES": "ad9d9d2c8837e5ac5b5c333d95014c29",
"assets/FontManifest.json": "0b1d34b1a6eb6e02b6185a26ef424d64",
"assets/AssetManifest.bin.json": "00c9e8bc9b7c9ed505eaf0463392f856",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/packages/jieba_flutter/assets/idf_dict.txt": "935d6acda4e203e98db10859cfbca0b5",
"assets/packages/jieba_flutter/assets/stop_words.txt": "83e223e668976ee72eedb525a1245396",
"assets/packages/jieba_flutter/assets/dict.big.txt": "5dc3eccfd0704b33b674d4d3909b9f1f",
"assets/packages/jieba_flutter/assets/prob_emit.txt": "9d835d9dd31ab1e8b5bee0b7cde86d8d",
"assets/packages/jieba_flutter/assets/dict.txt": "cce6651160071a052cb5d0c14baec8b5",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin": "4dc6614ff36e2dd94e11269d968e9807",
"assets/fonts/MaterialIcons-Regular.otf": "6858c0e980a55e6adcfbbfe0386610fb",
"assets/assets/images/app_icon.png": "d8459382b0e534b4d6bf24cf57dab0af",
"assets/assets/images/login_icon_apple.svg": "ec34ab71c8df83bebdf6f96df30fdc4d",
"assets/assets/images/login_icon_google.svg": "8f518f0a9de4b3c7adf116bfc48f7ea6",
"assets/assets/docs/privacy_policy.md": "d18c0a0c24c7dc2b8dd18eb1aa04aaca",
"assets/assets/docs/terms_of_service.md": "22b376503165b1f9212f2d66ffe59c8d",
"assets/assets/docs/about.md": "abd11c7937376bc172d732341d600fbf",
"assets/assets/prob_emit.txt": "9d835d9dd31ab1e8b5bee0b7cde86d8d",
"assets/assets/fonts/Righteous-Regular.ttf": "ff35ec5aa1a0f38f880024b89ca1e6bd",
"assets/assets/dict.txt": "cce6651160071a052cb5d0c14baec8b5",
"canvaskit/skwasm.js": "1ef3ea3a0fec4569e5d531da25f34095",
"canvaskit/skwasm_heavy.js": "413f5b2b2d9345f37de148e2544f584f",
"canvaskit/skwasm.js.symbols": "0088242d10d7e7d6d2649d1fe1bda7c1",
"canvaskit/canvaskit.js.symbols": "58832fbed59e00d2190aa295c4d70360",
"canvaskit/skwasm_heavy.js.symbols": "3c01ec03b5de6d62c34e17014d1decd3",
"canvaskit/skwasm.wasm": "264db41426307cfc7fa44b95a7772109",
"canvaskit/chromium/canvaskit.js.symbols": "193deaca1a1424049326d4a91ad1d88d",
"canvaskit/chromium/canvaskit.js": "5e27aae346eee469027c80af0751d53d",
"canvaskit/chromium/canvaskit.wasm": "24c77e750a7fa6d474198905249ff506",
"canvaskit/canvaskit.js": "140ccb7d34d0a55065fbd422b843add6",
"canvaskit/canvaskit.wasm": "07b9f5853202304d3b0749d9306573cc",
"canvaskit/skwasm_heavy.wasm": "8034ad26ba2485dab2fd49bdd786837b"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"main.dart.wasm",
"main.dart.mjs",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
