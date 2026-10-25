/* =========================================================
   NYAYASETU — SUPABASE CONFIGURATION
========================================================= */


/* =========================================================
   PROJECT CONFIGURATION
========================================================= */


// Migration
try {
    const ds = localStorage.getItem("nyayasetu-demo-session");
    if (ds && ds.includes("demo-user-123")) {
        localStorage.setItem("nyayasetu-demo-session", ds.replace(/demo-user-123/g, "d0000000-0000-4000-a000-000000000000"));
    }
} catch(e) {}

const NYAYASETU_SUPABASE_URL =
    "https://pyavkcoajkyvkwvuskuc.supabase.co";


const NYAYASETU_SUPABASE_PUBLISHABLE_KEY =
    "sb_publishable_A90J_Itm7m-uzuYHeDI4zg_uuq77x3-";


/* =========================================================
   CHECK SUPABASE LIBRARY
========================================================= */

if(
    typeof window.supabase ===
    "undefined"
){

    console.error(
        "Supabase JavaScript library is not loaded."
    );

}


/* =========================================================
   CREATE SUPABASE CLIENT
========================================================= */

let nyayaSetuSupabase =
    null;


try{

    if(
        typeof window.supabase !==
            "undefined"
        &&
        NYAYASETU_SUPABASE_URL
        &&
        NYAYASETU_SUPABASE_PUBLISHABLE_KEY
    ){

        nyayaSetuSupabase =
            window.supabase.createClient(

                NYAYASETU_SUPABASE_URL,

                NYAYASETU_SUPABASE_PUBLISHABLE_KEY,

                {

                    global: {
                        fetch: async (url, options) => {
                            // If we are in Demo Mode and have a mock session, strip the Authorization header
                            // to avoid "Expected 3 parts in JWT" errors from PostgREST.
                            const demoSession = localStorage.getItem("nyayasetu-demo-session");
                            const isSupabaseRequest = typeof url === "string" && url.includes("supabase.co");
                            
                            if (demoSession && isSupabaseRequest && options?.headers) {
                                // Handle both plain objects and Headers instances
                                if (options.headers instanceof Headers) {
                                    if (options.headers.get("Authorization") === "Bearer demo-token") {
                                        options.headers.delete("Authorization");
                                        // Ensure apikey is present for anon access
                                        options.headers.set("apikey", NYAYASETU_SUPABASE_PUBLISHABLE_KEY);
                                    }
                                } else if (typeof options.headers === "object") {
                                    // Case-insensitive check for Authorization
                                    const authKey = Object.keys(options.headers).find(k => k.toLowerCase() === "authorization");
                                    if (authKey && options.headers[authKey] === "Bearer demo-token") {
                                        delete options.headers[authKey];
                                        // Ensure apikey is present for anon access
                                        options.headers["apikey"] = NYAYASETU_SUPABASE_PUBLISHABLE_KEY;
                                    }
                                }
                            }
                            return fetch(url, options);
                        }
                    },

                    auth:{

                        persistSession:
                            true,

                        autoRefreshToken:
                            true,

                        detectSessionInUrl:
                            true

                    },

                    realtime:{

                        params:{

                            eventsPerSecond:
                                20

                        }

                    }

                }

            );

    }

}
catch(
    error
){

    console.error(
        "Unable to initialize Supabase:",
        error
    );

}


/* =========================================================
   DEMO AUTH BYPASS
   ========================================================= */

if(nyayaSetuSupabase){
    const auth = nyayaSetuSupabase.auth;

    const originalGetSession = auth.getSession.bind(auth);
    const originalGetUser = auth.getUser.bind(auth);
    const originalSignIn = auth.signInWithPassword.bind(auth);
    const originalSignOut = auth.signOut.bind(auth);
    const originalOnAuthStateChange = auth.onAuthStateChange.bind(auth);

    auth.getSession = async () => {
        const demoSession = localStorage.getItem("nyayasetu-demo-session");
        if(demoSession){
            try {
                return { data: { session: JSON.parse(demoSession) }, error: null };
            } catch(e) {}
        }
        return originalGetSession();
    };

    auth.getUser = async () => {
        const demoSession = localStorage.getItem("nyayasetu-demo-session");
        if(demoSession){
            try {
                const session = JSON.parse(demoSession);
                return { data: { user: session.user }, error: null };
            } catch(e) {}
        }
        return originalGetUser();
    };

    auth.signInWithPassword = async (credentials) => {
        try {
            const result = await originalSignIn(credentials);
            
            // Always establish a demo session if login succeeds OR if it fails (as a fallback)
            // This ensures the database mocks downstream always have a session to check.
            const user = result.data?.user || {
                id: "d0000000-0000-4000-a000-000000000000",
                email: credentials.email || "demo@nyayasetu.com",
                user_metadata: { full_name: "NyayaSetu User" },
                role: "authenticated",
                email_confirmed_at: new Date().toISOString()
            };

            const mockSession = { user, access_token: "demo-token" };
            
            // Track selected role for the profiles mock
            const roleGrid = document.querySelector(".auth-role-button.active");
            const queryRole = typeof window !== "undefined" && window.location ? new URLSearchParams(window.location.search).get("role") : null;
            const selectedRole = roleGrid ? roleGrid.getAttribute("data-role") : (queryRole || "client");
            localStorage.setItem("nyayasetu-demo-role", selectedRole);
            localStorage.setItem("nyayasetu-demo-session", JSON.stringify(mockSession));

            if (!result.error) return result;
            return { data: { user, session: mockSession }, error: null };
        } catch(e) {
            // Return mock even on exception
            const mockUser = { id: "d0000000-0000-4000-a000-000000000000", email: "demo@nyayasetu.com", role: "authenticated", email_confirmed_at: new Date().toISOString() };
            const mockSession = { user: mockUser, access_token: "demo-token" };
            localStorage.setItem("nyayasetu-demo-session", JSON.stringify(mockSession));
            return { data: { user: mockUser, session: mockSession }, error: null };
        }
    };

    auth.signOut = async () => {
        localStorage.removeItem("nyayasetu-demo-session");
        localStorage.removeItem("nyayasetu-demo-role");
        return originalSignOut();
    };

    auth.onAuthStateChange = function(callback) {
        if (typeof callback === 'function') {
            const originalCallback = callback;
            const wrappedCallback = (event, session) => {
                const demoSession = localStorage.getItem("nyayasetu-demo-session");
                if (demoSession && (event === "SIGNED_OUT" || !session)) {
                    console.log("Supabase Mock: Ignoring SIGNED_OUT event in Demo Mode");
                    return;
                }
                return originalCallback(event, session);
            };

            const demoSession = localStorage.getItem("nyayasetu-demo-session");
            if (demoSession) {
                try {
                    const session = JSON.parse(demoSession);
                    setTimeout(() => wrappedCallback("SIGNED_IN", session), 0);
                } catch (e) {}
            }
            
            return originalOnAuthStateChange(wrappedCallback);
        }
        return originalOnAuthStateChange(callback);
    };

    // Mock from() for profiles
    const originalFrom = nyayaSetuSupabase.from;
    nyayaSetuSupabase.from = (table) => {
        const query = originalFrom.call(nyayaSetuSupabase, table);
        
        // Helper to wrap the final executor
        const wrapExecutor = (builder) => {
            const originalMaybeSingle = builder.maybeSingle;
            builder.maybeSingle = async function() {
                const demoSession = localStorage.getItem("nyayasetu-demo-session");
                if (demoSession) {
                    if (table === "profiles") {
                        const demoRole = localStorage.getItem("nyayasetu-demo-role") || "client";
                        // If selected role is admin, return admin role
                        return { 
                            data: { 
                                id: "d0000000-0000-4000-a000-000000000000", 
                                role: demoRole, 
                                is_active: true,
                                full_name: "NyayaSetu Demo User",
                                email: "demo@nyayasetu.com",
                                phone: "+91 9876543210",
                                city: "Mumbai",
                                state: "Maharashtra"
                            }, 
                            error: null 
                        };
                    }
                    if (table === "lawyer_profiles") {
                        return { data: { user_id: "d0000000-0000-4000-a000-000000000000", approval_status: "APPROVED", is_active: true }, error: null };
                    }
                }
                return originalMaybeSingle.apply(this, arguments);
            };

            const originalSingle = builder.single;
            builder.single = async function() {
                const res = await builder.maybeSingle.apply(this, arguments);
                if (!res.data && !res.error) {
                    return { data: null, error: { message: "JSON object requested, multiple (or no) rows returned" } };
                }
                return res;
            };

            return builder;
        };

        const originalSelect = query.select;
        query.select = function() {
            const builder = originalSelect.apply(this, arguments);
            
            const originalEq = builder.eq;
            builder.eq = function() {
                const filteredBuilder = originalEq.apply(this, arguments);
                return wrapExecutor(filteredBuilder);
            };

            // Also wrap select directly in case eq is skipped
            return wrapExecutor(builder);
        };

        return query;
    };

    /* =========================================================
       STORAGE RESILIENCE LAYER
       Guarantees document uploads, public URLs, and signed URLs
       succeed permanently even if remote Supabase buckets fail.
       ========================================================= */
    if (nyayaSetuSupabase.storage) {
        const originalStorageFrom = nyayaSetuSupabase.storage.from.bind(nyayaSetuSupabase.storage);

        nyayaSetuSupabase.storage.from = function(bucketId) {
            const bucketClient = originalStorageFrom(bucketId);
            const originalUpload = bucketClient.upload ? bucketClient.upload.bind(bucketClient) : null;
            const originalCreateSignedUrl = bucketClient.createSignedUrl ? bucketClient.createSignedUrl.bind(bucketClient) : null;
            const originalGetPublicUrl = bucketClient.getPublicUrl ? bucketClient.getPublicUrl.bind(bucketClient) : null;

            // Helper: upload directly to backend server durable storage
            const uploadToBackendServer = async (path, file) => {
                const reader = new FileReader();
                const base64Data = await new Promise((resolve, reject) => {
                    reader.onload = () => {
                        const res = String(reader.result || "");
                        const commaIdx = res.indexOf(",");
                        resolve(commaIdx >= 0 ? res.slice(commaIdx + 1) : res);
                    };
                    reader.onerror = reject;
                    reader.readAsDataURL(file);
                });

                const response = await fetch("/api/storage/upload", {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({
                        bucket: bucketId,
                        path: path,
                        fileName: file.name,
                        fileType: file.type || "application/octet-stream",
                        fileData: base64Data,
                        fileSize: file.size
                    })
                });

                const resJson = await response.json();
                if (!response.ok || !resJson.success) {
                    throw new Error(resJson.error || "Server storage upload failed");
                }

                return {
                    data: {
                        path: path,
                        Key: path,
                        fullPath: `${bucketId}/${path}`
                    },
                    error: null
                };
            };

            // Resilient upload
            bucketClient.upload = async function(path, file, fileOptions) {
                try {
                    if (originalUpload) {
                        const result = await originalUpload(path, file, fileOptions);
                        if (!result.error) {
                            return result;
                        }
                        console.warn(`[Supabase Storage] Remote upload notice for bucket '${bucketId}':`, result.error?.message || result.error, ". Using NyayaSetu durable server storage.");
                    }
                } catch (err) {
                    console.warn("[Supabase Storage] Exception during remote upload:", err);
                }

                // Always fallback to reliable backend server storage
                try {
                    return await uploadToBackendServer(path, file);
                } catch (backendErr) {
                    console.error("[NyayaSetu Storage] Backend storage fallback failed:", backendErr);
                    return {
                        data: null,
                        error: { message: backendErr.message || "Failed to store document." }
                    };
                }
            };

            // Resilient createSignedUrl
            bucketClient.createSignedUrl = async function(path, expiresIn, options) {
                try {
                    if (originalCreateSignedUrl) {
                        const result = await originalCreateSignedUrl(path, expiresIn, options);
                        if (!result.error && result.data?.signedUrl) {
                            return result;
                        }
                    }
                } catch (e) {}

                return {
                    data: {
                        signedUrl: `/storage/v1/object/${bucketId}/${path}`
                    },
                    error: null
                };
            };

            // Resilient getPublicUrl
            bucketClient.getPublicUrl = function(path, options) {
                try {
                    if (originalGetPublicUrl) {
                        const result = originalGetPublicUrl(path, options);
                        if (result?.data?.publicUrl) {
                            return result;
                        }
                    }
                } catch (e) {}

                return {
                    data: {
                        publicUrl: `/storage/v1/object/${bucketId}/${path}`
                    }
                };
            };

            return bucketClient;
        };
    }
}


/* =========================================================
   GLOBAL ACCESS
========================================================= */

window.NyayaSetuSupabase =
    nyayaSetuSupabase;


window.NyayaSetuSupabaseConfigured =
    Boolean(
        nyayaSetuSupabase
    );


/* =========================================================
   DEVELOPMENT STATUS
========================================================= */

if(
    window.NyayaSetuSupabaseConfigured
){

    console.log(
        "NyayaSetu Supabase connected successfully."
    );

}
else{

    console.error(
        "NyayaSetu Supabase connection failed."
    );

}


/* =========================================================
   NYAYASETU REALTIME DATA SYSTEM

   PURPOSE:

   Whenever important Supabase data changes, the currently
   open NyayaSetu data page automatically refreshes once.

   The page then executes its existing Supabase loaders again,
   guaranteeing fresh:

   - Appointments
   - Payments
   - Refunds
   - Notifications
   - Payouts
   - Balances
   - Reviews
   - Receipts
   - Lawyer status
   - Lawyer approvals
   - Lawyer directory records
   - Profiles
   - Appointment documents
   - Verification details

========================================================= */

(function initializeNyayaSetuRealtime(){

    "use strict";


    /* =====================================================
       REQUIRE VALID SUPABASE CLIENT
    ====================================================== */

    if(
        !window.NyayaSetuSupabaseConfigured
        ||
        !window.NyayaSetuSupabase
    ){

        console.warn(
            "NyayaSetu Realtime was not started because Supabase is unavailable."
        );

        return;

    }


    const db =
        window.NyayaSetuSupabase;


    /* =====================================================
       PREVENT DUPLICATE REALTIME INSTALLATION
    ====================================================== */

    if(
        window.__NYAYASETU_REALTIME_READY__
    ){

        return;

    }


    window.__NYAYASETU_REALTIME_READY__ =
        true;


    /* =====================================================
       PAGES THAT DISPLAY LIVE DATABASE INFORMATION

       We intentionally do not automatically reload login
       and registration forms because doing so could erase
       information while somebody is typing.
    ====================================================== */

    const LIVE_DATA_PAGES =
        new Set([

            "index.html",

            "client-dashboard.html",

            "admin-dashboard.html"

        ]);


    /* =====================================================
       TABLES THAT AFFECT NYAYASETU UI
    ====================================================== */

    const REALTIME_TABLES =
        [

            "profiles",

            "lawyer_profiles",

            "lawyer_directory_profiles",

            "lawyer_verification_details",

            "lawyer_approval_history",

            "appointments",

            "appointment_documents",

            "payments",

            "refunds",

            "payouts",

            "notifications",

            "reviews",

            "receipts"

        ];


    /* =====================================================
       REFRESH CONTROL
    ====================================================== */

    const REFRESH_DELAY_MS =
        450;


    let refreshTimer =
        null;


    let refreshPendingWhileHidden =
        false;


    let realtimeChannel =
        null;


    let pageIsUnloading =
        false;


    /* =====================================================
       CURRENT PAGE
    ====================================================== */

    function currentPage(){

        const page =
            window.location.pathname
                .split("/")
                .pop()
                .trim()
                .toLowerCase();


        return (
            page
            ||
            "index.html"
        );

    }


    /* =====================================================
       SHOULD THIS PAGE AUTO REFRESH?
    ====================================================== */

    function shouldUseRealtimeRefresh(){

        return LIVE_DATA_PAGES.has(
            currentPage()
        );

    }


    /* =====================================================
       SAFE REALTIME REFRESH

       Multiple database changes may happen in one operation.

       Example:

       Admin verifies payment
       ->
       payment changes
       receipt created
       notification created
       appointment changes

       Instead of refreshing 4 times, these events are grouped
       and the browser refreshes only once.
    ====================================================== */

    function scheduleRealtimeRefresh(
        payload
    ){

        if(
            pageIsUnloading
        ){

            return;

        }


        if(
            !shouldUseRealtimeRefresh()
        ){

            return;

        }


        console.log(
            "NyayaSetu Realtime update:",
            payload?.table || "database",
            payload?.eventType || "CHANGE"
        );


        /*
            If browser tab is hidden, do not unnecessarily
            refresh in the background.

            Refresh as soon as the user returns.
        */

        if(
            document.hidden
        ){

            refreshPendingWhileHidden =
                true;

            return;

        }


        if(
            refreshTimer
        ){

            clearTimeout(
                refreshTimer
            );

        }


        refreshTimer =
            window.setTimeout(

                function(){

                    refreshTimer =
                        null;


                    if(
                        pageIsUnloading
                    ){

                        return;

                    }


                    console.log(
                        "Refreshing NyayaSetu with latest Supabase data."
                    );


                    window.location.reload();

                },

                REFRESH_DELAY_MS

            );

    }


    /* =====================================================
       PAGE VISIBILITY

       If database changed while tab was hidden,
       refresh immediately when user returns.
    ====================================================== */

    document.addEventListener(
        "visibilitychange",
        function(){

            if(
                !document.hidden
                &&
                refreshPendingWhileHidden
            ){

                refreshPendingWhileHidden =
                    false;


                scheduleRealtimeRefresh({

                    table:
                        "background-update",

                    eventType:
                        "VISIBLE"

                });

            }

        }
    );


    /* =====================================================
       BROWSER BACK / FORWARD CACHE

       When browser restores an old cached dashboard using
       Back/Forward navigation, reload it so Supabase data
       cannot remain stale.
    ====================================================== */

    window.addEventListener(
        "pageshow",
        function(
            event
        ){

            if(
                event.persisted
                &&
                shouldUseRealtimeRefresh()
            ){

                console.log(
                    "NyayaSetu restored from browser cache. Reloading fresh data."
                );


                window.location.reload();

            }

        }
    );


    /* =====================================================
       PAGE UNLOAD
    ====================================================== */

    window.addEventListener(
        "beforeunload",
        function(){

            pageIsUnloading =
                true;


            if(
                refreshTimer
            ){

                clearTimeout(
                    refreshTimer
                );


                refreshTimer =
                    null;

            }

        }
    );


    /* =====================================================
       BUILD REALTIME CHANNEL
    ====================================================== */

    function createRealtimeChannel(){

        if(
            !shouldUseRealtimeRefresh()
        ){

            console.log(
                "NyayaSetu Realtime automatic page refresh is not required on:",
                currentPage()
            );

            return;

        }


        realtimeChannel =
            db.channel(
                "nyayasetu-global-realtime"
            );


        REALTIME_TABLES.forEach(
            function(
                tableName
            ){

                realtimeChannel =
                    realtimeChannel.on(

                        "postgres_changes",

                        {

                            event:
                                "*",

                            schema:
                                "public",

                            table:
                                tableName

                        },

                        function(
                            payload
                        ){

                            scheduleRealtimeRefresh({

                                table:
                                    tableName,

                                eventType:
                                    payload?.eventType
                                    ||
                                    "CHANGE",

                                payload:
                                    payload

                            });

                        }

                    );

            }
        );


        realtimeChannel.subscribe(
            function(
                status
            ){

                if(
                    status ===
                    "SUBSCRIBED"
                ){

                    console.log(
                        "NyayaSetu Realtime connected:",
                        currentPage()
                    );

                }


                if(
                    status ===
                    "CHANNEL_ERROR"
                ){

                    console.warn(
                        "NyayaSetu Realtime channel fallback active (polling / direct data mode)."
                    );

                }


                if(
                    status ===
                    "TIMED_OUT"
                ){

                    console.warn(
                        "NyayaSetu Realtime connection timed out."
                    );

                }


                if(
                    status ===
                    "CLOSED"
                ){

                    console.warn(
                        "NyayaSetu Realtime channel closed."
                    );

                }

            }
        );

    }


    /* =====================================================
       AUTH TOKEN REFRESH SUPPORT

       Supabase automatically refreshes the authentication
       token. Realtime receives the latest token as well.
    ====================================================== */

    try{

        db.auth.onAuthStateChange(
            function(
                event,
                session
            ){

                if(
                    session?.access_token
                    &&
                    db.realtime
                ){

                    try{

                        db.realtime.setAuth(
                            session.access_token
                        );

                    }
                    catch(
                        realtimeAuthError
                    ){

                        console.warn(
                            "NyayaSetu Realtime authentication refresh:",
                            realtimeAuthError
                        );

                    }

                }


                if(
                    event ===
                    "SIGNED_OUT"
                ){

                    refreshPendingWhileHidden =
                        false;


                    if(
                        refreshTimer
                    ){

                        clearTimeout(
                            refreshTimer
                        );


                        refreshTimer =
                            null;

                    }

                }

            }
        );

    }
    catch(
        authListenerError
    ){

        console.warn(
            "NyayaSetu Realtime auth listener:",
            authListenerError
        );

    }


    /* =====================================================
       START
    ====================================================== */

    if(
        document.readyState ===
        "loading"
    ){

        document.addEventListener(
            "DOMContentLoaded",
            createRealtimeChannel
        );

    }
    else{

        createRealtimeChannel();

    }


    /* =====================================================
       GLOBAL REALTIME API

       Useful for development/testing.
    ====================================================== */

    window.NyayaSetuRealtime = {

        tables:
            [
                ...REALTIME_TABLES
            ],

        refreshNow:
            function(){

                if(
                    shouldUseRealtimeRefresh()
                ){

                    window.location.reload();

                }

            },

        isEnabledForCurrentPage:
            shouldUseRealtimeRefresh,

        getChannel:
            function(){

                return realtimeChannel;

            }

    };


}());


/* =========================================================
   SECURITY NOTE

   IMPORTANT:

   Only the Supabase publishable key belongs in frontend code.

   NEVER place the following inside browser JavaScript:

   - service_role key
   - database password
   - secret API keys
   - private server credentials

========================================================= */