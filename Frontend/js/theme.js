/* =========================================================
   =========================================================

                      NYAYASETU
                GLOBAL THEME SYSTEM V12

       DARK DEFAULT
       SETTINGS
       LOGOUT
       STABLE CUSTOM LAWYER FILTERS

   =========================================================
   ========================================================= */

(function () {


    /* =====================================================
                      PREVENT DOUBLE LOAD
    ====================================================== */

    if(
        window.__NYAYASETU_THEME_V12__
    ){

        return;

    }


    window.__NYAYASETU_THEME_V12__ =
        true;


    /* =====================================================
                         CONSTANTS
    ====================================================== */

    const THEME_KEY =
        "nyayasetu-theme";


    const MIGRATION_KEY =
        "nyayasetu-master-theme-v12";


    const VALID_THEMES = [
        "dark",
        "light"
    ];


    /* =====================================================
             ONE-TIME DEFAULT DARK MODE MIGRATION
    ====================================================== */

    if(
        localStorage.getItem(
            MIGRATION_KEY
        ) !== "done"
    ){


        localStorage.setItem(
            THEME_KEY,
            "dark"
        );


        localStorage.setItem(
            MIGRATION_KEY,
            "done"
        );

    }


    /* =====================================================
                       GET CURRENT THEME
    ====================================================== */

    function getTheme(){


        const savedTheme =
            localStorage.getItem(
                THEME_KEY
            );


        if(
            VALID_THEMES.includes(
                savedTheme
            )
        ){

            return savedTheme;

        }


        return "dark";

    }


    /* =====================================================
                       APPLY THEME
    ====================================================== */

    function applyThemeAttribute(
        theme
    ){


        const safeTheme =

            VALID_THEMES.includes(
                theme
            )

            ? theme

            : "dark";


        document.documentElement
            .setAttribute(
                "data-theme",
                safeTheme
            );


        document.documentElement
            .style.colorScheme =

                safeTheme === "dark"

                ? "dark"

                : "light";

    }


    /*
        Apply immediately before page becomes visible.
    */

    applyThemeAttribute(
        getTheme()
    );


    /* =====================================================
                    ENSURE THEME.CSS EXISTS
    ====================================================== */

    function ensureThemeStylesheet(){


        let stylesheet =

            Array
                .from(
                    document.querySelectorAll(
                        'link[rel="stylesheet"]'
                    )
                )
                .find(

                    function(link){


                        const href =

                            link.getAttribute(
                                "href"
                            ) || "";


                        return href.includes(
                            "theme.css"
                        );

                    }

                );


        if(
            !stylesheet
        ){


            stylesheet =
                document.createElement(
                    "link"
                );


            stylesheet.rel =
                "stylesheet";


            stylesheet.href =
                "../css/theme.css";


            document.head.appendChild(
                stylesheet
            );


            return;

        }


        /*
            theme.css must always be the LAST stylesheet.
            This makes it the visual authority.
        */

        document.head.appendChild(
            stylesheet
        );

    }


    ensureThemeStylesheet();


    /* =====================================================
              PERMANENT SETTINGS + FILTER UI FIXES
    ====================================================== */

    function ensurePermanentUiFixes(){


        const STYLE_ID =
            "nyayasetu-permanent-ui-fixes";


        let style =
            document.getElementById(
                STYLE_ID
            );


        if(
            !style
        ){


            style =
                document.createElement(
                    "style"
                );


            style.id =
                STYLE_ID;


            document.head.appendChild(
                style
            );

        }


        style.textContent = `

            /* ==============================================
               SETTINGS MENU — PERMANENT PROFESSIONAL LAYOUT
            ============================================== */

            .settings-wrapper{
                position:relative !important;
                flex:0 0 auto !important;
            }

            .settings-btn{
                width:46px !important;
                height:46px !important;
                padding:0 !important;
                display:flex !important;
                align-items:center !important;
                justify-content:center !important;
                border:1px solid var(--border) !important;
                border-radius:11px !important;
                background:var(--surface-3) !important;
                color:var(--text-secondary) !important;
                font-size:16px !important;
                cursor:pointer !important;
            }

            .settings-btn:hover{
                color:var(--gold) !important;
                border-color:var(--gold) !important;
            }

            .settings-menu{
                position:absolute !important;
                top:calc(100% + 12px) !important;
                right:0 !important;
                left:auto !important;
                width:280px !important;
                min-width:280px !important;
                max-width:280px !important;
                height:auto !important;
                min-height:0 !important;
                padding:15px !important;
                display:block !important;
                overflow:visible !important;
                background:var(--surface-1) !important;
                border:1px solid var(--border) !important;
                border-radius:17px !important;
                box-shadow:var(--shadow-lg) !important;
                opacity:0 !important;
                visibility:hidden !important;
                pointer-events:none !important;
                transform:translateY(-8px) !important;
                transition:opacity .18s ease, transform .18s ease, visibility .18s ease !important;
                z-index:999999 !important;
            }

            .settings-menu.open{
                opacity:1 !important;
                visibility:visible !important;
                pointer-events:auto !important;
                transform:translateY(0) !important;
            }

            .settings-menu-header{
                width:100% !important;
                display:flex !important;
                align-items:center !important;
                gap:11px !important;
                padding:0 0 13px 0 !important;
                margin:0 0 13px 0 !important;
                border-bottom:1px solid var(--border) !important;
            }

            .settings-menu-header-icon{
                width:39px !important;
                height:39px !important;
                flex:0 0 39px !important;
                display:flex !important;
                align-items:center !important;
                justify-content:center !important;
                border-radius:11px !important;
                color:var(--gold) !important;
                background:var(--gold-surface) !important;
            }

            .settings-menu-header > div:last-child{
                min-width:0 !important;
            }

            .settings-menu-header strong{
                display:block !important;
                margin:0 !important;
                color:var(--text-main) !important;
                font-size:14px !important;
                font-weight:700 !important;
                line-height:1.4 !important;
                text-transform:none !important;
            }

            .settings-menu-header span{
                display:block !important;
                margin-top:3px !important;
                color:var(--text-muted) !important;
                font-size:12px !important;
                line-height:1.4 !important;
                text-transform:none !important;
            }

            .settings-section-label{
                display:block !important;
                width:100% !important;
                margin:0 0 8px 0 !important;
                color:var(--text-muted) !important;
                font-size:11px !important;
                font-weight:600 !important;
                letter-spacing:.06em !important;
                text-transform:uppercase !important;
            }

            .theme-options{
                width:100% !important;
                display:grid !important;
                grid-template-columns:minmax(0,1fr) minmax(0,1fr) !important;
                gap:8px !important;
                margin-bottom:12px !important;
            }

            .theme-option{
                width:100% !important;
                min-width:0 !important;
                min-height:43px !important;
                padding:0 9px !important;
                display:flex !important;
                align-items:center !important;
                justify-content:center !important;
                gap:7px !important;
                border:1px solid var(--border) !important;
                border-radius:10px !important;
                background:var(--surface-2) !important;
                color:var(--text-secondary) !important;
                font-size:13px !important;
                font-weight:500 !important;
                white-space:nowrap !important;
            }

            .theme-option:hover,
            .theme-option.active{
                color:var(--gold) !important;
                border-color:var(--gold) !important;
                background:var(--gold-soft) !important;
            }

            .settings-divider{
                display:block !important;
                width:100% !important;
                height:1px !important;
                margin:16px 0 !important;
                padding:0 !important;
                background:var(--border) !important;
                border:0 !important;
            }

            .settings-divider[hidden]{
                display:none !important;
            }

            .settings-logout{
                width:100% !important;
                min-height:43px !important;
                padding:0 12px !important;
                display:flex !important;
                align-items:center !important;
                justify-content:center !important;
                gap:8px !important;
                border:1px solid var(--border) !important;
                border-radius:10px !important;
                background:var(--surface-2) !important;
                color:var(--text-secondary) !important;
                font-size:13px !important;
                font-weight:500 !important;
                text-transform:none !important;
            }

            .settings-logout[hidden]{
                display:none !important;
            }

            .settings-logout span,
            [data-dashboard],
            [data-dashboard] span{
                text-transform:none !important;
                letter-spacing:normal !important;
            }

            .settings-logout:hover{
                color:var(--danger) !important;
                border-color:var(--danger) !important;
            }

            .nav-buttons,
            .nav-actions,
            .navbar,
            .header{
                overflow:visible !important;
            }

            /* ==============================================
               LAWYER FILTERS — PERMANENT PROFESSIONAL LAYOUT
            ============================================== */

            .lawyer-filters{
                overflow:visible !important;
            }

            .lawyer-filter.ns-native-filter-hidden{
                display:none !important;
            }

            .ns-filter-select{
                position:relative !important;
                width:100% !important;
                min-width:0 !important;
                align-self:stretch !important;
            }

            .ns-filter-select.open{
                z-index:1000 !important;
            }

            .ns-filter-trigger{
                appearance:none !important;
                -webkit-appearance:none !important;
                width:100% !important;
                min-width:0 !important;
                height:54px !important;
                margin:0 !important;
                padding:0 15px !important;
                display:flex !important;
                align-items:center !important;
                justify-content:space-between !important;
                gap:12px !important;
                border:1px solid var(--border) !important;
                border-radius:12px !important;
                outline:0 !important;
                background:var(--input-bg) !important;
                color:var(--text-main) !important;
                box-shadow:none !important;
                font:inherit !important;
                font-size:14px !important;
                font-weight:600 !important;
                line-height:1 !important;
                text-align:left !important;
                cursor:pointer !important;
                transition:border-color .18s ease, background .18s ease, box-shadow .18s ease !important;
            }

            .ns-filter-trigger:hover{
                border-color:var(--border-strong) !important;
            }

            .ns-filter-select.open .ns-filter-trigger{
                border-color:var(--gold) !important;
                box-shadow:0 0 0 3px rgba(215,167,45,.08) !important;
            }

            .ns-filter-trigger-text{
                min-width:0 !important;
                overflow:hidden !important;
                white-space:nowrap !important;
                text-overflow:ellipsis !important;
            }

            .ns-filter-chevron{
                width:18px !important;
                flex:0 0 18px !important;
                display:flex !important;
                align-items:center !important;
                justify-content:center !important;
                color:var(--text-secondary) !important;
                font-size:12px !important;
                transition:transform .18s ease, color .18s ease !important;
            }

            .ns-filter-select.open .ns-filter-chevron{
                transform:rotate(180deg) !important;
                color:var(--gold) !important;
            }

            .ns-filter-menu{
                position:absolute !important;
                top:calc(100% + 8px) !important;
                left:0 !important;
                right:auto !important;
                width:100% !important;
                min-width:100% !important;
                max-width:320px !important;
                max-height:280px !important;
                margin:0 !important;
                padding:6px !important;
                display:block !important;
                overflow-x:hidden !important;
                overflow-y:auto !important;
                border:1px solid var(--border-strong) !important;
                border-radius:12px !important;
                background:var(--surface-1) !important;
                color:var(--text-main) !important;
                box-shadow:0 16px 38px rgba(0,0,0,.32) !important;
                opacity:0 !important;
                visibility:hidden !important;
                pointer-events:none !important;
                transform:translateY(-6px) !important;
                transform-origin:top center !important;
                transition:opacity .16s ease, transform .16s ease, visibility .16s ease !important;
                z-index:1001 !important;
            }

            .ns-filter-select.open .ns-filter-menu{
                opacity:1 !important;
                visibility:visible !important;
                pointer-events:auto !important;
                transform:translateY(0) !important;
            }

            .ns-filter-option{
                appearance:none !important;
                -webkit-appearance:none !important;
                width:100% !important;
                min-height:40px !important;
                                margin:0 !important;
                padding:9px 10px !important;
                display:flex !important;
                align-items:center !important;
                justify-content:space-between !important;
                gap:12px !important;
                border:0 !important;
                border-radius:8px !important;
                outline:0 !important;
                background:transparent !important;
                color:var(--text-secondary) !important;
                box-shadow:none !important;
                font:inherit !important;
                font-size:14px !important;
                font-weight:500 !important;
                line-height:1.35 !important;
                text-align:left !important;
                cursor:pointer !important;
                transition:background .15s ease, color .15s ease !important;
            }

            .ns-filter-option + .ns-filter-option{
                margin-top:2px !important;
            }

            .ns-filter-option:hover,
            .ns-filter-option:focus-visible{
                background:var(--surface-3) !important;
                color:var(--text-main) !important;
            }

            .ns-filter-option.selected{
                background:var(--gold-soft) !important;
                color:var(--gold) !important;
            }

            .ns-filter-option-label{
                min-width:0 !important;
                overflow:hidden !important;
                white-space:nowrap !important;
                text-overflow:ellipsis !important;
            }

            .ns-filter-check{
                width:16px !important;
                flex:0 0 16px !important;
                display:flex !important;
                align-items:center !important;
                justify-content:center !important;
                color:var(--gold) !important;
                font-size:11px !important;
                opacity:0 !important;
            }

            .ns-filter-option.selected .ns-filter-check{
                opacity:1 !important;
            }

            @media(max-width:900px){

                .ns-filter-menu{
                    max-width:none !important;
                }

            }

        `;

    }


    /* =====================================================
                         SET THEME
    ====================================================== */

    function setTheme(
        theme
    ){


        const safeTheme =

            VALID_THEMES.includes(
                theme
            )

            ? theme

            : "dark";


        localStorage.setItem(
            THEME_KEY,
            safeTheme
        );


        applyThemeAttribute(
            safeTheme
        );


        updateThemeButtons();

    }


    /* =====================================================
                   AUTHENTICATION PAGES
    ====================================================== */

    function isAuthPage(){


        const page =

            window.location
                .pathname
                .split("/")
                .pop()
                .toLowerCase();


        return (

            page === "login.html"

            ||

            page === "register.html"

            ||

            page === "client-register.html"

            ||

            page === "lawyer-register.html"

        );

    }


    /* =====================================================
                     CREATE SETTINGS UI
    ====================================================== */

    function createSettingsUI(){


        const wrapper =
            document.createElement(
                "div"
            );


        wrapper.className =
            "settings-wrapper";


        wrapper.dataset
            .nyayasetuSettings =
            "true";


        wrapper.innerHTML = `

            <button
                type="button"
                class="settings-btn"
                data-settings-button
                aria-label="Open Settings"
                aria-expanded="false"
                title="Settings"
            >

                <i class="fa-solid fa-gear"></i>

            </button>


            <div
                class="settings-menu"
                data-settings-menu
            >


                <div class="settings-menu-header">


                    <div
                        class="settings-menu-header-icon"
                    >

                        <i class="fa-solid fa-gear"></i>

                    </div>


                    <div>

                        <strong>
                            Settings
                        </strong>

                        <span>
                            NyayaSetu preferences
                        </span>

                    </div>


                </div>


                <span
                    class="settings-section-label"
                >

                    Appearance

                </span>


                <div class="theme-options">


                    <button
                        type="button"
                        class="theme-option"
                        data-theme-select="light"
                    >

                        <i class="fa-solid fa-sun"></i>

                        <span>
                            Day Mode
                        </span>

                    </button>


                    <button
                        type="button"
                        class="theme-option"
                        data-theme-select="dark"
                    >

                        <i class="fa-solid fa-moon"></i>

                        <span>
                            Dark Mode
                        </span>

                    </button>


                </div>


                <div
                    class="settings-divider"
                    data-account-divider
                    hidden
                ></div>


                <button
                    type="button"
                    class="settings-logout"
                    data-logout
                    hidden
                >

                    <i
                        class="fa-solid fa-right-from-bracket"
                    ></i>

                    <span>
                        Logout
                    </span>

                </button>


            </div>

        `;


        return wrapper;

    }


    /* =====================================================
                  INSTALL SETTINGS BUTTON
    ====================================================== */

    function ensureSettingsButton(){


        if(
            isAuthPage()
        ){


            document
                .querySelectorAll(
                    "[data-nyayasetu-settings]"
                )
                .forEach(

                    function(element){

                        element.remove();

                    }

                );


            return;

        }


        const actions =

            document.querySelector(
                ".nav-buttons"
            )

            ||

            document.querySelector(
                ".nav-actions"
            );


        if(
            !actions
        ){

            return;

        }


        actions
            .querySelectorAll(
                ".settings-wrapper"
            )
            .forEach(

                function(element){

                    element.remove();

                }

            );


        actions.appendChild(
            createSettingsUI()
        );


        attachSettingsEvents();

        updateThemeButtons();

        refreshDashboardControls();

    }


    /* =====================================================
                 UPDATE THEME BUTTON STATE
    ====================================================== */

    function updateThemeButtons(){


        const theme =
            getTheme();


        document
            .querySelectorAll(
                "[data-theme-select]"
            )
            .forEach(

                function(button){


                    button.classList.toggle(

                        "active",

                        button.dataset.themeSelect ===
                            theme

                    );

                }

            );

    }


    /* =====================================================
                      CLOSE SETTINGS
    ====================================================== */

    function closeSettings(){


        document
            .querySelectorAll(
                "[data-settings-menu].open"
            )
            .forEach(

                function(menu){


                    menu.classList.remove(
                        "open"
                    );


                    const button =

                        menu
                            .closest(
                                ".settings-wrapper"
                            )
                            ?.querySelector(
                                "[data-settings-button]"
                            );


                    if(
                        button
                    ){


                        button.setAttribute(
                            "aria-expanded",
                            "false"
                        );

                    }

                }

            );

    }


    /* =====================================================
                  ACCOUNT / DASHBOARD ROUTING
    ====================================================== */

    function dashboardForRole(
        role
    ){


        if(
            role === "client"
        ){

            return "client-dashboard.html";

        }

        return "";

    }


    /* =====================================================
                  PUBLIC LOGIN / REGISTER BUTTONS
    ====================================================== */

    function setPublicAccountButtons(
        authenticated
    ){


        const actions =

            document.querySelector(
                ".nav-buttons"
            )

            ||

            document.querySelector(
                ".nav-actions"
            );


        if(
            !actions
        ){

            return;

        }


        const loginButton =
            actions.querySelector(
                ".login-btn"
            );


        const registerButton =
            actions.querySelector(
                ".register-btn"
            );


        if(
            loginButton
        ){


            loginButton.hidden =
                authenticated;


            loginButton.style.setProperty(
                "display",
                authenticated
                    ? "none"
                    : "",
                authenticated
                    ? "important"
                    : ""
            );

        }


        if(
            registerButton
        ){


            registerButton.hidden =
                authenticated;


            registerButton.style.setProperty(
                "display",
                authenticated
                    ? "none"
                    : "",
                authenticated
                    ? "important"
                    : ""
            );

        }

    }


    /* =====================================================
                    RESOLVE SIGNED-IN ROLE
    ====================================================== */

    async function resolveSignedInRole(){


        const supabase =

            window.NyayaSetuSupabase

            ||

            window.supabaseClient

            ||

            null;


        /*
            IMPORTANT:
            sessionStorage is only a display cache. It must NEVER
            be treated as proof that somebody is still signed in.

            This prevents a previous Client/Lawyer/Admin role from
            surviving logout, refresh, account switching or browser
            back/forward restoration.
        */

        if(
            !supabase
            ||
            !supabase.auth
        ){


            setPublicAccountButtons(
                false
            );


            return "";

        }


        try{


            const {
                data:{
                    session
                },
                error:
                    sessionError
            } =

                await supabase
                    .auth
                    .getSession();


            if(
                sessionError
            ){


                throw sessionError;

            }


            if(
                !session?.user
            ){


                sessionStorage.removeItem(
                    "nyayasetuRole"
                );


                sessionStorage.removeItem(
                    "nyayasetuDashboard"
                );


                setPublicAccountButtons(
                    false
                );


                return "";

            }


            /*
                A real Supabase session exists, therefore Login
                and Register can safely disappear.
            */

            setPublicAccountButtons(
                true
            );


            const {
                data:
                    profile,
                error:
                    profileError
            } =

                await supabase
                    .from(
                        "profiles"
                    )
                    .select(
                        "role, is_active"
                    )
                    .eq(
                        "id",
                        session.user.id
                    )
                    .maybeSingle();


            if(
                profileError
                ||
                !profile
                ||
                profile.is_active === false
            ){


                sessionStorage.removeItem(
                    "nyayasetuRole"
                );


                sessionStorage.removeItem(
                    "nyayasetuDashboard"
                );


                return "";

            }


            const role =

                String(
                    profile.role
                    ||
                    ""
                )
                .toLowerCase();


            const dashboard =
                dashboardForRole(
                    role
                );


            if(
                !dashboard
            ){


                sessionStorage.removeItem(
                    "nyayasetuRole"
                );


                sessionStorage.removeItem(
                    "nyayasetuDashboard"
                );


                return "";

            }


            /*
                Cache only AFTER Supabase has confirmed the current
                authenticated user's real database role.
            */

            sessionStorage.setItem(
                "nyayasetuRole",
                role
            );


            sessionStorage.setItem(
                "nyayasetuDashboard",
                dashboard
            );


            return role;

        }
        catch(error){


            console.warn(
                "NyayaSetu dashboard role check:",
                error
            );


            /*
                On an auth/profile lookup failure, do not expose a
                cached dashboard button from a previous session.
            */

            sessionStorage.removeItem(
                "nyayasetuRole"
            );


            sessionStorage.removeItem(
                "nyayasetuDashboard"
            );


            return "";

        }

    }


    /* =====================================================
                    REFRESH ACCOUNT CONTROLS
    ====================================================== */

    async function refreshDashboardControls(){


        const role =
            await resolveSignedInRole();


        const dashboard =
            dashboardForRole(
                role
            );


        document
            .querySelectorAll(
                "[data-dashboard]"
            )
            .forEach(

                function(button){


                    button.hidden =
                        !dashboard;


                    if(
                        dashboard
                    ){


                        button.style.removeProperty(
                            "display"
                        );

                    }
                    else{


                        button.style.setProperty(
                            "display",
                            "none",
                            "important"
                        );

                    }


                    button.dataset.dashboardHref =
                        dashboard;

                }

            );


        document
            .querySelectorAll(
                "[data-account-divider]"
            )
            .forEach(

                function(divider){


                    divider.hidden =
                        !dashboard;


                    if(
                        dashboard
                    ){


                        divider.style.removeProperty(
                            "display"
                        );

                    }
                    else{


                        divider.style.setProperty(
                            "display",
                            "none",
                            "important"
                        );

                    }

                }

            );


        document
            .querySelectorAll(
                "[data-logout]"
            )
            .forEach(

                function(button){


                    button.hidden =
                        !dashboard;


                    if(
                        dashboard
                    ){


                        button.style.removeProperty(
                            "display"
                        );

                    }
                    else{


                        button.style.setProperty(
                            "display",
                            "none",
                            "important"
                        );

                    }

                }

            );

    }


    /* =====================================================
                       OPEN DASHBOARD
    ====================================================== */

    async function openDashboard(){


        /*
            Always resolve the CURRENT Supabase session and database
            role before opening a dashboard. Do not trust a stale
            sessionStorage route.
        */

        const role =
            await resolveSignedInRole();


        const dashboard =
            dashboardForRole(
                role
            );


        if(
            dashboard
        ){


            window.location.href =
                dashboard;


            return;

        }


        /*
            No valid active NyayaSetu account is signed in.
        */

        sessionStorage.removeItem(
            "nyayasetuRole"
        );


        sessionStorage.removeItem(
            "nyayasetuDashboard"
        );


        window.location.href =
            "login.html";

    }


    /* =====================================================
                    SETTINGS EVENTS
    ====================================================== */

    function attachSettingsEvents(){


        document
            .querySelectorAll(
                "[data-settings-button]"
            )
            .forEach(

                function(button){


                    if(
                        button.dataset.bound ===
                        "true"
                    ){

                        return;

                    }


                    button.dataset.bound =
                        "true";


                    button.addEventListener(

                        "click",

                        function(event){


                            event.preventDefault();

                            event.stopPropagation();


                            const menu =

                                button
                                    .closest(
                                        ".settings-wrapper"
                                    )
                                    ?.querySelector(
                                        "[data-settings-menu]"
                                    );


                            if(
                                !menu
                            ){

                                return;

                            }


                            const currentlyOpen =

                                menu.classList
                                    .contains(
                                        "open"
                                    );


                            closeSettings();

                            closeAllCustomFilters();


                            if(
                                !currentlyOpen
                            ){


                                menu.classList.add(
                                    "open"
                                );


                                button.setAttribute(
                                    "aria-expanded",
                                    "true"
                                );

                            }

                        }

                    );

                }

            );


        document
            .querySelectorAll(
                "[data-settings-menu]"
            )
            .forEach(

                function(menu){


                    if(
                        menu.dataset.bound ===
                        "true"
                    ){

                        return;

                    }


                    menu.dataset.bound =
                        "true";


                    menu.addEventListener(

                        "click",

                        function(event){


                            event.stopPropagation();

                        }

                    );

                }

            );


        document
            .querySelectorAll(
                "[data-theme-select]"
            )
            .forEach(

                function(button){


                    if(
                        button.dataset.themeBound ===
                        "true"
                    ){

                        return;

                    }


                    button.dataset.themeBound =
                        "true";


                    button.addEventListener(

                        "click",

                        function(){


                            setTheme(
                                button.dataset.themeSelect
                            );


                            closeSettings();

                        }

                    );

                }

            );


        document
            .querySelectorAll(
                "[data-dashboard]"
            )
            .forEach(

                function(button){


                    if(
                        button.dataset.dashboardBound ===
                        "true"
                    ){

                        return;

                    }


                    button.dataset.dashboardBound =
                        "true";


                    button.addEventListener(

                        "click",

                        async function(){


                            closeSettings();


                            await openDashboard();

                        }

                    );

                }

            );


        document
            .querySelectorAll(
                "[data-logout]"
            )
            .forEach(

                function(button){


                    if(
                        button.dataset.logoutBound ===
                        "true"
                    ){

                        return;

                    }


                    button.dataset.logoutBound =
                        "true";


                    button.addEventListener(

                        "click",

                        logoutNyayaSetu

                    );

                }

            );

    }


    /* =====================================================
                          LOGOUT
    ====================================================== */

    async function logoutNyayaSetu(){


        try{


            if(
                window.NyayaSetuSupabase
                &&
                window.NyayaSetuSupabase.auth
            ){


                await window
                    .NyayaSetuSupabase
                    .auth
                    .signOut();

            }


            if(
                window.supabaseClient
                &&
                window.supabaseClient.auth
            ){


                await window
                    .supabaseClient
                    .auth
                    .signOut();

            }

        }
        catch(error){


            console.error(
                "NyayaSetu logout error:",
                error
            );

        }


        sessionStorage.removeItem(
            "nyayasetuRole"
        );


        sessionStorage.removeItem(
            "nyayasetuDashboard"
        );


        setPublicAccountButtons(
            false
        );


        window.location.href =
            "login.html";

    }


    /* =====================================================
       =====================================================

                    LAWYER FILTER SYSTEM

       =====================================================
       ===================================================== */


    /* =====================================================
          REMOVE BROKEN/DUPLICATE FILTER COMPONENTS
    ====================================================== */

    function cleanExistingCustomFilters(){


        document
            .querySelectorAll(
                ".ns-filter-select"
            )
            .forEach(

                function(wrapper){


                    wrapper.remove();

                }

            );


        document
            .querySelectorAll(
                ".lawyer-filter"
            )
            .forEach(

                function(select){


                    delete select.dataset
                        .customFilterReady;


                    select.classList.remove(
                        "ns-native-filter-hidden"
                    );


                    select.style.removeProperty(
                        "display"
                    );


                    select.removeAttribute(
                        "aria-hidden"
                    );


                    select.tabIndex =
                        0;

                }

            );

    }


    /* =====================================================
                 INITIALIZE CUSTOM FILTERS
    ====================================================== */

    function initializeCustomLawyerFilters(){


        const selects =
            document.querySelectorAll(
                ".lawyer-filter"
            );


        if(
            selects.length ===
            0
        ){

            return;

        }


        cleanExistingCustomFilters();


        selects.forEach(

            function(select){


                select.dataset
                    .customFilterReady =
                    "true";


                select.classList.add(
                    "ns-native-filter-hidden"
                );


                select.style.setProperty(
                    "display",
                    "none",
                    "important"
                );


                select.setAttribute(
                    "aria-hidden",
                    "true"
                );


                select.tabIndex =
                    -1;


                /* =============================================
                         CUSTOM WRAPPER
                ============================================== */

                const wrapper =
                    document.createElement(
                        "div"
                    );


                wrapper.className =
                    "ns-filter-select";


                wrapper.dataset
                    .generatedBy =
                    "nyayasetu-v12";


                wrapper.dataset
                    .selectId =
                    select.id;


                /* =============================================
                          TRIGGER BUTTON
                ============================================== */

                const trigger =
                    document.createElement(
                        "button"
                    );


                trigger.type =
                    "button";


                trigger.className =
                    "ns-filter-trigger";


                trigger.setAttribute(
                    "aria-haspopup",
                    "listbox"
                );


                trigger.setAttribute(
                    "aria-expanded",
                    "false"
                );


                const triggerText =
                    document.createElement(
                        "span"
                    );


                triggerText.className =
                    "ns-filter-trigger-text";


                const chevron =
                    document.createElement(
                        "span"
                    );


                chevron.className =
                    "ns-filter-chevron";


                chevron.innerHTML =
                    '<i class="fa-solid fa-chevron-down"></i>';


                trigger.appendChild(
                    triggerText
                );


                trigger.appendChild(
                    chevron
                );


                /* =============================================
                              MENU
                ============================================== */

                const menu =
                    document.createElement(
                        "div"
                    );


                menu.className =
                    "ns-filter-menu";


                menu.setAttribute(
                    "role",
                    "listbox"
                );


                /* =============================================
                             OPTIONS
                ============================================== */

                Array
                    .from(
                        select.options
                    )
                    .forEach(

                        function(option){


                            const optionButton =
                                document.createElement(
                                    "button"
                                );


                            optionButton.type =
                                "button";


                            optionButton.className =
                                "ns-filter-option";


                            optionButton.dataset.value =
                                option.value;


                            optionButton.setAttribute(
                                "role",
                                "option"
                            );


                            const label =
                                document.createElement(
                                    "span"
                                );


                            label.className =
                                "ns-filter-option-label";


                            label.textContent =
                                option
                                    .textContent
                                    .trim();


                            const check =
                                document.createElement(
                                    "span"
                                );


                            check.className =
                                "ns-filter-check";


                            check.innerHTML =
                                '<i class="fa-solid fa-check"></i>';


                            optionButton.appendChild(
                                label
                            );


                            optionButton.appendChild(
                                check
                            );


                            menu.appendChild(
                                optionButton
                            );


                            optionButton.addEventListener(

                                "click",

                                function(event){


                                    event.preventDefault();

                                    event.stopPropagation();


                                    select.value =
                                        option.value;


                                    select.dispatchEvent(

                                        new Event(
                                            "change",
                                            {
                                                bubbles:true
                                            }
                                        )

                                    );


                                    syncOneCustomFilter(
                                        select
                                    );


                                    closeAllCustomFilters();

                                }

                            );

                        }

                    );


                wrapper.appendChild(
                    trigger
                );


                wrapper.appendChild(
                    menu
                );


                select.insertAdjacentElement(
                    "afterend",
                    wrapper
                );


                /* =============================================
                         OPEN / CLOSE MENU
                ============================================== */

                trigger.addEventListener(

                    "click",

                    function(event){


                        event.preventDefault();

                        event.stopPropagation();


                        const wasOpen =

                            wrapper.classList
                                .contains(
                                    "open"
                                );


                        closeAllCustomFilters();

                        closeSettings();


                        if(
                            !wasOpen
                        ){


                            wrapper.classList.add(
                                "open"
                            );


                            trigger.setAttribute(
                                "aria-expanded",
                                "true"
                            );

                        }

                    }

                );


                select.addEventListener(

                    "change",

                    function(){


                        syncOneCustomFilter(
                            select
                        );

                    }

                );


                syncOneCustomFilter(
                    select
                );

            }

        );


        attachExternalFilterSync();

    }


    /* =====================================================
                    SYNC ONE FILTER
    ====================================================== */

    function syncOneCustomFilter(
        select
    ){


        if(
            !select
            ||
            !select.id
        ){

            return;

        }


        const wrapper =

            document.querySelector(

                `.ns-filter-select[data-select-id="${select.id}"]`

            );


        if(
            !wrapper
        ){

            return;

        }


        const selectedOption =

            select.options[
                select.selectedIndex
            ];


        const triggerText =

            wrapper.querySelector(
                ".ns-filter-trigger-text"
            );


        if(
            triggerText
            &&
            selectedOption
        ){


            triggerText.textContent =

                selectedOption
                    .textContent
                    .trim();

        }


        wrapper
            .querySelectorAll(
                ".ns-filter-option"
            )
            .forEach(

                function(button){


                    const selected =

                        button.dataset.value ===
                        select.value;


                    button.classList.toggle(
                        "selected",
                        selected
                    );


                    button.setAttribute(
                        "aria-selected",
                        selected
                            ? "true"
                            : "false"
                    );

                }

            );

    }


    /* =====================================================
                   SYNC ALL FILTERS
    ====================================================== */

    function syncAllCustomFilters(){


        document
            .querySelectorAll(
                ".lawyer-filter"
            )
            .forEach(

                function(select){


                    syncOneCustomFilter(
                        select
                    );

                }

            );

    }
        /* =====================================================
             CATEGORY + CLEAR BUTTON SYNCHRONIZATION
    ====================================================== */

    function attachExternalFilterSync(){


        document
            .querySelectorAll(
                ".view-lawyers-btn"
            )
            .forEach(

                function(button){


                    if(
                        button.dataset
                            .nyayasetuFilterSync ===
                        "true"
                    ){

                        return;

                    }


                    button.dataset
                        .nyayasetuFilterSync =
                        "true";


                    button.addEventListener(

                        "click",

                        function(){


                            window.setTimeout(

                                syncAllCustomFilters,

                                0

                            );

                        }

                    );

                }

            );


        const clearButton =

            document.getElementById(
                "clearFiltersBtn"
            );


        if(
            clearButton
            &&
            clearButton.dataset
                .nyayasetuFilterSync !==
            "true"
        ){


            clearButton.dataset
                .nyayasetuFilterSync =
                "true";


            clearButton.addEventListener(

                "click",

                function(){


                    window.setTimeout(

                        syncAllCustomFilters,

                        0

                    );

                }

            );

        }

    }


    /* =====================================================
                 CLOSE ALL CUSTOM FILTERS
    ====================================================== */

    function closeAllCustomFilters(){


        document
            .querySelectorAll(
                ".ns-filter-select.open"
            )
            .forEach(

                function(wrapper){


                    wrapper.classList.remove(
                        "open"
                    );


                    const trigger =

                        wrapper.querySelector(
                            ".ns-filter-trigger"
                        );


                    if(
                        trigger
                    ){


                        trigger.setAttribute(
                            "aria-expanded",
                            "false"
                        );

                    }

                }

            );

    }


    /* =====================================================
                       GLOBAL EVENTS
    ====================================================== */

    function attachGlobalEvents(){


        if(
            document.documentElement
                .dataset
                .nyayasetuGlobalBound ===
            "true"
        ){

            return;

        }


        document.documentElement
            .dataset
            .nyayasetuGlobalBound =
            "true";


        document.addEventListener(

            "click",

            function(){


                closeSettings();

                closeAllCustomFilters();

            }

        );


        document.addEventListener(

            "keydown",

            function(event){


                if(
                    event.key ===
                    "Escape"
                ){


                    closeSettings();

                    closeAllCustomFilters();

                }

            }

        );

    }


    /* =====================================================
                  AUTH STATE SYNCHRONIZATION
    ====================================================== */

    function attachAuthStateSynchronization(){


        const supabase =

            window.NyayaSetuSupabase

            ||

            window.supabaseClient

            ||

            null;


        if(
            !supabase
            ||
            !supabase.auth
            ||
            window.__NYAYASETU_AUTH_STATE_BOUND__
        ){

            return;

        }


        window.__NYAYASETU_AUTH_STATE_BOUND__ =
            true;


        supabase
            .auth
            .onAuthStateChange(

                function(
                    event,
                    session
                ){


                    if(
                        event ===
                        "SIGNED_OUT"
                        ||
                        !session?.user
                    ){


                        sessionStorage.removeItem(
                            "nyayasetuRole"
                        );


                        sessionStorage.removeItem(
                            "nyayasetuDashboard"
                        );


                        setPublicAccountButtons(
                            false
                        );

                    }
                    else{


                        setPublicAccountButtons(
                            true
                        );

                    }


                    window.setTimeout(

                        refreshDashboardControls,

                        0

                    );

                }

            );

    }


    /* =====================================================
                    SETTINGS RESTORATION
    ====================================================== */

    function observeNavbar(){


        if(
            !document.body
        ){

            return;

        }


        const observer =
            new MutationObserver(

                function(){


                    if(
                        isAuthPage()
                    ){

                        return;

                    }


                    const actions =

                        document.querySelector(
                            ".nav-buttons"
                        )

                        ||

                        document.querySelector(
                            ".nav-actions"
                        );


                    if(
                        actions
                        &&
                        !actions.querySelector(
                            "[data-nyayasetu-settings]"
                        )
                    ){


                        ensureSettingsButton();

                    }

                }

            );


        observer.observe(

            document.body,

            {
                childList:true,
                subtree:true
            }

        );

    }


    /* =====================================================
                   REPAIR SETTINGS CONTENT
    ====================================================== */

    function repairSettingsMenu(){


        document
            .querySelectorAll(
                "[data-dashboard]"
            )
            .forEach(

                function(button){


                    const span =
                        button.querySelector(
                            "span"
                        );


                    if(
                        span
                    ){


                        span.textContent =
                            "Your Dashboard";

                    }
                    else{


                        const textNodes =
                            Array
                                .from(
                                    button.childNodes
                                )
                                .filter(

                                    function(node){

                                        return (
                                            node.nodeType ===
                                            Node.TEXT_NODE
                                            &&
                                            node.textContent
                                                .trim()
                                        );

                                    }

                                );


                        textNodes.forEach(

                            function(node){

                                node.textContent =
                                    " Your Dashboard ";

                            }

                        );

                    }

                }

            );

    }


    /* =====================================================
                 FORCE NAV AUTH VISIBILITY
    ====================================================== */

    async function synchronizeNavigationAccountState(){


        try{


            const supabase =

                window.NyayaSetuSupabase

                ||

                window.supabaseClient

                ||

                null;


            if(
                !supabase
                ||
                !supabase.auth
            ){


                return;

            }


            const {
                data:{
                    session
                }
            } =

                await supabase
                    .auth
                    .getSession();


            setPublicAccountButtons(
                Boolean(
                    session?.user
                )
            );


        }
        catch(error){


            console.warn(
                "NyayaSetu navigation auth sync:",
                error
            );

        }

    }


    /* =====================================================
                         INITIALIZE
    ====================================================== */

    function initialize(){


        ensureThemeStylesheet();


        ensurePermanentUiFixes();


        applyThemeAttribute(
            getTheme()
        );


        ensureSettingsButton();


        repairSettingsMenu();


        initializeCustomLawyerFilters();


        attachSettingsEvents();


        attachGlobalEvents();


        updateThemeButtons();


        refreshDashboardControls();


        synchronizeNavigationAccountState();


        attachAuthStateSynchronization();


        observeNavbar();


        /*
            Once the browser has completed its first visual
            render, re-apply the permanent UI authority.
        */

        window.requestAnimationFrame(

            function(){


                ensureThemeStylesheet();


                ensurePermanentUiFixes();


                repairSettingsMenu();


                synchronizeNavigationAccountState();

            }

        );


        /*
            Some NyayaSetu pages load Supabase after theme.js.
            Re-check everything when the full page has loaded.
        */

        window.addEventListener(

            "load",

            function(){


                ensurePermanentUiFixes();


                repairSettingsMenu();


                refreshDashboardControls();


                synchronizeNavigationAccountState();


                attachAuthStateSynchronization();


                syncAllCustomFilters();

            },

            {
                once:true
            }

        );


        /*
            supabase.js can announce that the persistent
            Supabase client is ready.
        */

        window.addEventListener(

            "nyayasetu:supabase-ready",

            function(){


                refreshDashboardControls();


                synchronizeNavigationAccountState();


                attachAuthStateSynchronization();

            }

        );


        /*
            Existing NyayaSetu code can also dispatch this
            custom event after sign-in or sign-out.
        */

        window.addEventListener(

            "nyayasetu:auth-change",

            function(event){


                const authEvent =

                    event?.detail?.event

                    ||

                    "";


                if(
                    authEvent ===
                    "SIGNED_OUT"
                ){


                    sessionStorage.removeItem(
                        "nyayasetuRole"
                    );


                    sessionStorage.removeItem(
                        "nyayasetuDashboard"
                    );


                    setPublicAccountButtons(
                        false
                    );

                }


                window.setTimeout(

                    function(){


                        refreshDashboardControls();


                        synchronizeNavigationAccountState();

                    },

                    0

                );

            }

        );


        /*
            Back/forward navigation can restore an older DOM
            snapshot. Repair the menu and session display.
        */

        window.addEventListener(

            "pageshow",

            function(){


                ensurePermanentUiFixes();


                repairSettingsMenu();


                refreshDashboardControls();


                synchronizeNavigationAccountState();


                window.setTimeout(

                    syncAllCustomFilters,

                    0

                );

            }

        );


        /*
            Re-sync when returning to the browser tab.
        */

        window.addEventListener(

            "focus",

            function(){


                repairSettingsMenu();


                refreshDashboardControls();


                synchronizeNavigationAccountState();

            }

        );

    }
        /* =====================================================
                       PUBLIC API
    ====================================================== */

    window.NyayaSetuTheme = {


        getTheme:
            getTheme,


        setTheme:
            setTheme,


        logout:
            logoutNyayaSetu,


        refreshSettings:
            ensureSettingsButton,


        refreshAccountControls:
            refreshDashboardControls,


        openDashboard:
            openDashboard,


        syncFilters:
            syncAllCustomFilters,


        rebuildFilters:
            initializeCustomLawyerFilters,


        repairSettings:
            repairSettingsMenu,


        syncNavigation:
            synchronizeNavigationAccountState

    };


    /* =====================================================
                       DOM READY
    ====================================================== */

    if(
        document.readyState ===
        "loading"
    ){


        document.addEventListener(

            "DOMContentLoaded",

            initialize,

            {
                once:true
            }

        );

    }
    else{


        initialize();

    }


})();