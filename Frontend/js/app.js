/* =========================================================
                     NYAYASETU APP.JS
========================================================= */

document.addEventListener(
    "DOMContentLoaded",
    function(){

        "use strict";


        /* =====================================================
           SUPABASE PUBLIC CONFIGURATION

           Publishable key is safe for browser use.
           RLS only exposes APPROVED + ACTIVE lawyers publicly.
        ====================================================== */

        const SUPABASE_URL =
            "https://pyavkcoajkyvkwvuskuc.supabase.co";


        const SUPABASE_PUBLISHABLE_KEY =
            "sb_publishable_A90J_Itm7m-uzuYHeDI4zg_uuq77x3-";


        /* =====================================================
           CATEGORY NAMES
        ====================================================== */

        const categoryNames = {

            criminal:"Criminal Law",

            family:"Family Law",

            property:"Property Law",

            corporate:"Corporate Law",

            civil:"Civil Law",

            financial:"Financial Law",

            cyber:"Cyber Law",

            labour:"Labour & Employment Law",

            taxation:"Taxation & GST",

            constitutional:"Constitutional Law",

            consumer:"Consumer Protection",

            intellectual_property:"Intellectual Property",

            environmental:"Environmental Law"

        };


        /* =====================================================
           MASTER LAWYER ARRAY

           Public directory profiles are now loaded from
           Supabase instead of being hard-coded in this file.
        ====================================================== */

        const lawyers =
            [];


        /* =====================================================
           LOCAL LAWYER IMAGE URL

           Converts the database filename into an absolute browser
           URL based on the current page. This makes the exact same
           Lawyer photo survive Homepage -> Booking -> Payment ->
           Confirmation and dashboard navigation without depending
           on the next page's relative folder location.
        ====================================================== */

        function buildLocalLawyerImageUrl(
            profilePhotoPath
        ){

            if(
                !profilePhotoPath
            ){

                return "";

            }


            const safePath =
                String(
                    profilePhotoPath
                )
                .split(
                    "/"
                )
                .map(
                    function(
                        part
                    ){

                        return encodeURIComponent(
                            part
                        );

                    }
                )
                .join(
                    "/"
                );


            return new URL(
                "../images/lawyers/"
                +
                safePath,
                window.location.href
            ).href;

        }


        /* =====================================================
           LOAD 48 DIRECTORY LAWYERS FROM SUPABASE
        ====================================================== */

        async function loadDirectorySupabaseLawyers(){

            let records = [];

            try {
                const endpoint =
                    SUPABASE_URL
                    +
                    "/rest/v1/lawyer_directory_profiles"
                    +
                    "?select=id,legacy_id,linked_user_id,test_route_user_id,display_name,gender,legal_category,years_experience,seed_rating,seed_review_count,consultation_fee,locality,city,state,languages,availability,profile_photo_path,source,is_active,is_bookable,is_test_bookable"
                    +
                    "&is_active=eq.true"
                    +
                    "&order=legacy_id.asc";

                const response =
                    await fetch(
                        endpoint,
                        {
                            method:
                                "GET",

                            headers:{
                                apikey:
                                    SUPABASE_PUBLISHABLE_KEY,

                                Authorization:
                                    "Bearer "
                                    +
                                    SUPABASE_PUBLISHABLE_KEY,

                                Accept:
                                    "application/json"
                            }
                        }
                    );

                if(response.ok){
                    const data = await response.json();
                    if(Array.isArray(data) && data.length > 0){
                        records = data;
                    }
                }
            } catch(err) {
                console.warn("Direct Supabase fetch fallback engaged:", err.message);
            }

            if(records.length === 0){
                try {
                    const fallbackResp = await fetch("/api/lawyers");
                    if(fallbackResp.ok){
                        const fallbackData = await fallbackResp.json();
                        if(Array.isArray(fallbackData) && fallbackData.length > 0){
                            records = fallbackData;
                        }
                    }
                } catch(e) {
                    console.warn("Local lawyers fallback fetch:", e);
                }
            }

            if(records.length === 0){
                try {
                    const localResp = await fetch("/rest/v1/lawyer_directory_profiles");
                    if(localResp.ok){
                        const localData = await localResp.json();
                        if(Array.isArray(localData) && localData.length > 0){
                            records = localData;
                        }
                    }
                } catch(e) {}
            }

            if(records.length === 0){
                return;
            }


            records.forEach(
                function(
                    record
                ){

                    const category =
                        String(
                            record.legal_category
                            ||
                            ""
                        )
                        .trim()
                        .toLowerCase();


                    if(
                        !categoryNames[
                            category
                        ]
                    ){

                        return;

                    }


                    const displayName =
                        String(
                            record.display_name
                            ||
                            "Lawyer"
                        )
                        .trim();


                    const localImage =
                        buildLocalLawyerImageUrl(
                            record.profile_photo_path
                        );


                    lawyers.push({

                        id:
                            String(
                                record.legacy_id
                                ||
                                record.id
                            ),

                        directoryId:
                            record.id,

                        legacy_id:
                            record.legacy_id,

                        genuineLinkedUserId:
                            record.linked_user_id
                            ||
                            null,

                        testRouteUserId:
                            record.test_route_user_id
                            ||
                            null,

                        databaseId:
                            record.linked_user_id
                            ||
                            record.test_route_user_id
                            ||
                            (record.legacy_id ? ("d0000000-0000-4000-b000-" + String(record.legacy_id).padStart(12, '0')) : ("d0000000-0000-4000-b000-" + String(record.id).padStart(12, '0'))),

                        source:
                            "directory",

                        routingMode:
                            "linked",

                        bookable:
                            true,

                        category:
                            category,

                        categoryName:
                            categoryNames[
                                category
                            ],

                        name:
                            displayName,

                        gender:
                            record.gender
                            ||
                            "",

                        experience:
                            Number(
                                record.years_experience
                                ||
                                0
                            ),

                        rating:
                            Number(
                                record.seed_rating
                                ||
                                0
                            ),

                        reviews:
                            Number(
                                record.seed_review_count
                                ||
                                0
                            ),

                        fee:
                            Number(
                                record.consultation_fee
                                ||
                                0
                            ),

                        locality:
                            record.locality
                            ||
                            "",

                        city:
                            record.city
                            ||
                            "",

                        state:
                            record.state
                            ||
                            "",

                        languages:
                            Array.isArray(
                                record.languages
                            )
                            ?
                            record.languages
                            :
                            [],

                        availability:
                            record.availability
                            ||
                            "week",

                        image:
                            localImage

                    });

                }
            );


            console.log(
                "Supabase directory lawyers loaded:",
                records.length
            );

        }


        /* =====================================================
           DISPLAY SETTINGS
        ====================================================== */

        const HOMEPAGE_VISIBLE_LIMIT =
            24;


        const PREVIEW_PER_CATEGORY =
            4;


        let showAllLawyers =
            false;


        /* =====================================================
           ELEMENTS
        ====================================================== */

        const lawyerGrid =
            document.querySelector(
                "#lawyerGrid"
            );


        const resultCount =
            document.querySelector(
                "#lawyerResultCount"
            );


        const emptyState =
            document.querySelector(
                "#lawyerEmpty"
            );


        const searchInput =
            document.querySelector(
                "#lawyerSearch"
            );


        const categoryFilter =
            document.querySelector(
                "#lawCategory"
            );


        const experienceFilter =
            document.querySelector(
                "#experienceFilter"
            );


        const feeFilter =
            document.querySelector(
                "#feeFilter"
            );


        const languageFilter =
            document.querySelector(
                "#languageFilter"
            );


        const ratingFilter =
            document.querySelector(
                "#ratingFilter"
            );


        const availabilityFilter =
            document.querySelector(
                "#availabilityFilter"
            );


        const clearFiltersButton =
            document.querySelector(
                "#clearFiltersBtn"
            );


        const viewAllLawyersButton =
            document.querySelector(
                "#viewAllLawyersBtn"
            );


        /* =====================================================
           HELPERS
        ====================================================== */

        function escapeHtml(
            value
        ){

            return String(
                value ?? ""
            )
            .replace(
                /&/g,
                "&amp;"
            )
            .replace(
                /</g,
                "&lt;"
            )
            .replace(
                />/g,
                "&gt;"
            )
            .replace(
                /"/g,
                "&quot;"
            )
            .replace(
                /'/g,
                "&#039;"
            );

        }


        function availabilityText(
            value
        ){

            if(
                value ===
                "today"
            ){

                return "Available Today";

            }


            if(
                value ===
                "tomorrow"
            ){

                return "Available Tomorrow";

            }


            return "Available This Week";

        }


        function formatLocation(
            lawyer
        ){

            const places =
                [
                    lawyer.locality,
                    lawyer.city,
                    lawyer.state
                ]
                .map(
                    value =>
                        String(
                            value || ""
                        )
                        .trim()
                )
                .filter(
                    Boolean
                );


            return [
                ...new Set(
                    places
                )
            ]
            .join(
                ", "
            );

        }


        function lawyerAvatarDataUrl(
            name
        ){

            const cleanName =
                String(
                    name || "Lawyer"
                )
                .replace(
                    /^Adv\.?\s*/i,
                    ""
                )
                .trim();


            const words =
                cleanName
                    .split(
                        /\s+/
                    )
                    .filter(
                        Boolean
                    );


            const initials =
                (
                    (words[0]?.[0] || "L")
                    +
                    (words.length > 1 ? words[words.length - 1][0] : "")
                )
                .toUpperCase();


            const svg =
                `<svg xmlns="http://www.w3.org/2000/svg" width="640" height="420" viewBox="0 0 640 420">`
                +
                `<rect width="640" height="420" fill="#172433"/>`
                +
                `<circle cx="320" cy="170" r="78" fill="#24384d"/>`
                +
                `<path d="M170 420c18-106 76-158 150-158s132 52 150 158" fill="#24384d"/>`
                +
                `<text x="320" y="190" text-anchor="middle" font-family="Arial,sans-serif" font-size="64" font-weight="700" fill="#e7b52e">${initials}</text>`
                +
                `</svg>`;


            return (
                "data:image/svg+xml;charset=UTF-8,"
                +
                encodeURIComponent(
                    svg
                )
            );

        }


        function publicPhotoUrl(
            path
        ){

            if(
                !path
            ){

                return "";

            }


            const safePath =
                String(
                    path
                )
                .split(
                    "/"
                )
                .map(
                    encodeURIComponent
                )
                .join(
                    "/"
                );


            return (
                SUPABASE_URL
                +
                "/storage/v1/object/public/lawyer-profile-photos/"
                +
                safePath
            );

        }


        /* =====================================================
           LOAD REAL APPROVED + ACTIVE LAWYERS

           These are authenticated Lawyer accounts and are
           therefore genuinely bookable.
        ====================================================== */

        async function loadApprovedSupabaseLawyers(){

            try{

                const endpoint =
                    SUPABASE_URL
                    +
                    "/rest/v1/lawyer_profiles"
                    +
                    "?select=*&approval_status=eq.APPROVED&is_active=eq.true";


                const response =
                    await fetch(
                        endpoint,
                        {
                            method:
                                "GET",

                            headers:{
                                apikey:
                                    SUPABASE_PUBLISHABLE_KEY,

                                Authorization:
                                    "Bearer "
                                    +
                                    SUPABASE_PUBLISHABLE_KEY,

                                Accept:
                                    "application/json"
                            }
                        }
                    );


                let records = [];
                if(response.ok){
                    const data = await response.json();
                    if(Array.isArray(data)){
                        records = data;
                    }
                }

                if(records.length === 0){
                    try {
                        const localResp = await fetch("/api/lawyer-profiles");
                        if(localResp.ok){
                            const localData = await localResp.json();
                            if(Array.isArray(localData)){
                                records = localData.filter(r => r.approval_status === "APPROVED" && r.is_active);
                            }
                        }
                    } catch(e) {}
                }

                if(
                    !Array.isArray(
                        records
                    ) || records.length === 0
                ){

                    return;

                }


                records.forEach(
                    function(
                        record
                    ){

                        let category =
                            String(
                                record.legal_category
                                ||
                                ""
                            )
                            .trim()
                            .toLowerCase();


                        if(
                            !categoryNames[
                                category
                            ]
                        ){

                            if (category.includes("civil") && !category.includes("criminal")) category = "civil";
                            else if (category.includes("corp") || category.includes("commercial")) category = "corporate";
                            else if (category.includes("cyber") || category.includes("it law")) category = "cyber";
                            else if (category.includes("prop") || category.includes("real estate")) category = "property";
                            else if (category.includes("tax")) category = "taxation";
                            else if (category.includes("constitut")) category = "constitutional";
                            else if (category.includes("crim")) category = "criminal";
                            else if (category.includes("fam") || category.includes("matrimon")) category = "family";
                            else if (category.includes("intellect") || category.includes("ip") || category.includes("patent") || category.includes("trademark")) category = "intellectual_property";
                            else if (category.includes("labour") || category.includes("labor") || category.includes("employ")) category = "labour";
                            else if (category.includes("financ") || category.includes("bank")) category = "financial";
                            else if (category.includes("consum")) category = "consumer";
                            else if (category.includes("environ")) category = "environmental";

                        }


                        if(
                            !categoryNames[
                                category
                            ]
                        ){

                            return;

                        }


                        let displayName =
                            String(
                                record.display_name
                                ||
                                "Lawyer"
                            )
                            .trim();


                        if(
                            !displayName
                                .toLowerCase()
                                .startsWith(
                                    "adv."
                                )
                        ){

                            displayName =
                                "Adv. "
                                +
                                displayName;

                        }


                        const languages =
                            Array.isArray(
                                record.languages
                            )
                            ?
                            record.languages
                            :
                            [];


                        /*
                            IMPORTANT:
                            Always keep every APPROVED + ACTIVE real Lawyer
                            as a separate public card.

                            Directory/demo cards may route internally to the
                            same authenticated Lawyer account, but that must
                            never hide the real Lawyer's own profile card.
                        */


                        const lawyerDbId =
                            record.user_id || record.id;


                        const id =
                            "supabase-"
                            +
                            lawyerDbId;


                        const existingLawyer =
                            lawyers.find(
                                lawyer =>
                                    lawyer.id ===
                                    id
                                    ||
                                    lawyer.databaseId ===
                                    lawyerDbId
                                    ||
                                    lawyer.genuineLinkedUserId ===
                                    lawyerDbId
                                    ||
                                    (
                                        lawyer.name
                                        &&
                                        displayName
                                        &&
                                        lawyer.name.toLowerCase().trim() ===
                                        displayName.toLowerCase().trim()
                                    )
                            );


                        if(
                            existingLawyer
                        ){

                            if(
                                Array.isArray(record.practice_areas)
                                &&
                                record.practice_areas.length > 0
                                &&
                                (!existingLawyer.practiceAreas || existingLawyer.practiceAreas.length === 0)
                            ){

                                existingLawyer.practiceAreas =
                                    record.practice_areas;

                            }


                            if(
                                record.bar_council_number
                                &&
                                !existingLawyer.barCouncilNumber
                            ){

                                existingLawyer.barCouncilNumber =
                                    record.bar_council_number;

                            }


                            if(
                                record.state_bar_council
                                &&
                                !existingLawyer.stateBarCouncil
                            ){

                                existingLawyer.stateBarCouncil =
                                    record.state_bar_council;

                            }


                            existingLawyer.supabaseProfileId =
                                record.id;


                            return;

                        }


                        lawyers.push({

                            id:
                                id,

                            databaseId:
                                lawyerDbId,

                            source:
                                "supabase",

                            bookable:
                                true,

                            category:
                                category,

                            categoryName:
                                categoryNames[
                                    category
                                ],

                            name:
                                displayName,

                            gender:
                                "",

                            experience:
                                Number(
                                    record.years_experience
                                    ||
                                    0
                                ),

                            rating:
                                5.0,

                            reviews:
                                0,

                            fee:
                                Number(
                                    record.consultation_fee
                                    ||
                                    0
                                ),

                            locality:
                                "",

                            city:
                                record.city
                                ||
                                "",

                            state:
                                record.state
                                ||
                                "",

                            languages:
                                languages,

                            practiceAreas:
                                Array.isArray(record.practice_areas)
                                ? record.practice_areas
                                : [],

                            availability:
                                "week",

                            image:
                                publicPhotoUrl(
                                    record.profile_photo_path
                                )

                        });

                    }
                );


                console.log(
                    "Approved Supabase lawyers loaded:",
                    records.length
                );


            }
            catch(error){

                console.error(
                    "NyayaSetu real Lawyer sync error:",
                    error
                );

            }

        }
                /* =====================================================
           HOMEPAGE LAWYER ORDER
        ====================================================== */

        function getHomepageLawyerOrder(){

            const previewLawyers =
                [];


            const hiddenLawyers =
                [];


            Object
                .keys(
                    categoryNames
                )
                .forEach(
                    function(
                        category
                    ){

                        const categoryLawyers =
                            lawyers.filter(
                                lawyer =>
                                    lawyer.category ===
                                    category
                            );


                        previewLawyers.push(
                            ...categoryLawyers.slice(
                                0,
                                PREVIEW_PER_CATEGORY
                            )
                        );


                        hiddenLawyers.push(
                            ...categoryLawyers.slice(
                                PREVIEW_PER_CATEGORY
                            )
                        );

                    }
                );


            return [

                ...previewLawyers,

                ...hiddenLawyers

            ];

        }


        /* =====================================================
           DEFAULT FILTER STATE
        ====================================================== */

        function isDefaultFilterState(){

            if(
                !searchInput
                ||
                !categoryFilter
                ||
                !experienceFilter
                ||
                !feeFilter
                ||
                !languageFilter
                ||
                !ratingFilter
                ||
                !availabilityFilter
            ){

                return true;

            }


            return (

                searchInput
                    .value
                    .trim()
                    ===
                    ""

                &&

                categoryFilter.value
                    ===
                    "all"

                &&

                experienceFilter.value
                    ===
                    "all"

                &&

                feeFilter.value
                    ===
                    "all"

                &&

                languageFilter.value
                    ===
                    "all"

                &&

                ratingFilter.value
                    ===
                    "all"

                &&

                availabilityFilter.value
                    ===
                    "all"

            );

        }


        /* =====================================================
           CREATE LAWYER CARD
        ====================================================== */

        function createLawyerCard(
            lawyer
        ){

            const article =
                document.createElement(
                    "article"
                );


            article.className =
                "lawyer-card";


            article.dataset
                .lawyerSource =
                lawyer.source || "static";


            const oneRupeeBadge =

                lawyer.fee ===
                1

                ?

                `

                    <span class="one-rupee-badge">

                        ₹1 Consultation

                    </span>

                `

                :

                "";


            const location =
                formatLocation(
                    lawyer
                );


            const ratingText =
                lawyer.reviews >
                0

                ?
                `

                    <strong>
                        ★ ${escapeHtml(
                            lawyer.rating
                        )}
                    </strong>

                    <span>
                        ${escapeHtml(
                            lawyer.reviews
                        )}
                        Reviews
                    </span>

                `

                :

                `

                    <strong>
                        ★ New
                    </strong>

                    <span>
                        No Reviews Yet
                    </span>

                `;


            article.innerHTML =
                `

                    <div class="lawyer-photo">


                        <img

                            src="${escapeHtml(
                                lawyer.image
                                ||
                                lawyerAvatarDataUrl(
                                    lawyer.name
                                )
                            )}"

                            alt="${escapeHtml(
                                lawyer.name
                            )}"

                            class="lawyer-profile-image"

                        >


                        <span class="verified-badge">

                            <i class="fa-solid fa-circle-check"></i>

                            Verified

                        </span>


                        ${oneRupeeBadge}


                    </div>


                    <div class="lawyer-info">


                        <h3>

                            ${escapeHtml(
                                lawyer.name
                            )}

                        </h3>


                        <span class="lawyer-specialization">

                            ${escapeHtml(
                                lawyer.categoryName
                            )}
                            Specialist

                        </span>


                        <div class="lawyer-rating">

                            ${ratingText}

                        </div>


                        <div class="lawyer-details">


                            <span>

                                <i class="fa-solid fa-briefcase"></i>

                                ${escapeHtml(
                                    lawyer.experience
                                )}

                                ${
                                    lawyer.experience ===
                                    1
                                    ?
                                    "Year"
                                    :
                                    "Years"
                                }

                                Experience

                            </span>


                            <span>

                                <i class="fa-solid fa-language"></i>

                                ${
                                    lawyer.languages.length
                                    >
                                    0

                                    ?
                                    escapeHtml(
                                        lawyer.languages.join(
                                            ", "
                                        )
                                    )

                                    :
                                    "Language information unavailable"
                                }

                            </span>


                            <span>

                                <i class="fa-solid fa-location-dot"></i>

                                ${
                                    escapeHtml(
                                        location || "India"
                                    )
                                }

                            </span>


                            <span class="available">

                                <i class="fa-solid fa-circle"></i>

                                ${availabilityText(
                                    lawyer.availability
                                )}

                            </span>


                        </div>


                        <div class="lawyer-bottom">


                            <div class="consultation-fee">


                                <small>

                                    Consultation Fee

                                </small>


                                <strong>

                                    ₹${Number(
                                        lawyer.fee || 0
                                    )
                                    .toLocaleString(
                                        "en-IN"
                                    )}

                                </strong>


                            </div>


                            <button

                                type="button"

                                class="book-lawyer-btn"

                                data-lawyer-id="${escapeHtml(
                                    String(lawyer.id)
                                )}"

                                data-database-id="${escapeHtml(
                                    String(lawyer.databaseId || "")
                                )}"

                                title="Book consultation with ${escapeHtml(
                                    lawyer.name
                                )}"

                            >

                                Book Now

                            </button>


                        </div>


                    </div>

                `;


            const lawyerImageElement =
                article.querySelector(
                    ".lawyer-profile-image"
                );


            if(
                lawyerImageElement
            ){

                lawyerImageElement.addEventListener(
                    "error",
                    function(){

                        const fallback =
                            lawyerAvatarDataUrl(
                                lawyer.name
                            );


                        if(
                            lawyerImageElement.src !==
                            fallback
                        ){

                            lawyerImageElement.src =
                                fallback;

                        }

                    },
                    { once:true }
                );

            }


            return article;

        }


        /* =====================================================
           FILTER LAWYERS
        ====================================================== */

        function getFilteredLawyers(){

            if(
                !searchInput
            ){

                return [
                    ...lawyers
                ];

            }


            const search =
                searchInput
                    .value
                    .trim()
                    .toLowerCase();


            const selectedCategory =
                categoryFilter.value;


            const selectedExperience =
                experienceFilter.value;


            const selectedFee =
                feeFilter.value;


            const selectedLanguage =
                languageFilter.value;


            const selectedRating =
                ratingFilter.value;


            const selectedAvailability =
                availabilityFilter.value;


            return lawyers.filter(
                function(
                    lawyer
                ){

                    const searchable =
                        (

                            lawyer.name
                            +
                            " "
                            +
                            lawyer.categoryName
                            +
                            " "
                            +
                            lawyer.locality
                            +
                            " "
                            +
                            lawyer.city
                            +
                            " "
                            +
                            lawyer.state
                            +
                            " "
                            +
                            lawyer.languages.join(
                                " "
                            )

                        )
                        .toLowerCase();


                    const matchesSearch =

                        search ===
                        ""

                        ||

                        searchable.includes(
                            search
                        );


                    const matchesCategory =

                        selectedCategory ===
                        "all"

                        ||

                        lawyer.category ===
                        selectedCategory;


                    const matchesExperience =

                        selectedExperience ===
                        "all"

                        ||

                        lawyer.experience >=
                        Number(
                            selectedExperience
                        );


                    let matchesFee =
                        true;


                    if(
                        selectedFee ===
                        "1"
                    ){

                        matchesFee =
                            lawyer.fee ===
                            1;

                    }
                    else if(
                        selectedFee !==
                        "all"
                    ){

                        matchesFee =
                            lawyer.fee <=
                            Number(
                                selectedFee
                            );

                    }


                    const matchesLanguage =

                        selectedLanguage ===
                        "all"

                        ||

                        lawyer.languages.some(
                            language =>
                                String(
                                    language
                                )
                                .toLowerCase()
                                ===
                                selectedLanguage
                        );


                    const matchesRating =

                        selectedRating ===
                        "all"

                        ||

                        lawyer.rating >=
                        Number(
                            selectedRating
                        );


                    let matchesAvailability =
                        true;


                    if(
                        selectedAvailability ===
                        "today"
                    ){

                        matchesAvailability =
                            lawyer.availability ===
                            "today";

                    }
                    else if(
                        selectedAvailability ===
                        "tomorrow"
                    ){

                        matchesAvailability =
                            lawyer.availability ===
                            "tomorrow";

                    }
                    else if(
                        selectedAvailability ===
                        "week"
                    ){

                        matchesAvailability =
                            [

                                "today",
                                "tomorrow",
                                "week"

                            ]
                            .includes(
                                lawyer.availability
                            );

                    }


                    return (

                        matchesSearch

                        &&

                        matchesCategory

                        &&

                        matchesExperience

                        &&

                        matchesFee

                        &&

                        matchesLanguage

                        &&

                        matchesRating

                        &&

                        matchesAvailability

                    );

                }
            );

        }


        /* =====================================================
           CATEGORY COUNTS
        ====================================================== */

        function updateCategoryCounts(){

            document
                .querySelectorAll(
                    ".view-lawyers-btn"
                )
                .forEach(
                    function(
                        button
                    ){

                        const category =
                            button.dataset
                                .category;


                        const count =
                            lawyers.filter(
                                lawyer =>
                                    lawyer.category ===
                                    category
                            )
                            .length;


                        button.innerHTML =
                            `

                                View ${count}
                                ${
                                    count === 1
                                    ?
                                    "Lawyer"
                                    :
                                    "Lawyers"
                                }

                                <i class="fa-solid fa-arrow-right"></i>

                            `;

                    }
                );

        }


        /* =====================================================
           VIEW ALL BUTTON
        ====================================================== */
                function updateViewAllButton(
            totalLawyers,
            defaultView
        ){

            if(
                !viewAllLawyersButton
            ){

                return;

            }


            if(
                !defaultView
            ){

                viewAllLawyersButton.hidden =
                    true;

                return;

            }


            if(
                totalLawyers <=
                HOMEPAGE_VISIBLE_LIMIT
            ){

                viewAllLawyersButton.hidden =
                    true;

                return;

            }


            viewAllLawyersButton.hidden =
                false;


            if(
                showAllLawyers
            ){

                viewAllLawyersButton.innerHTML =
                    `

                        Show Less

                        <i class="fa-solid fa-arrow-up"></i>

                    `;

            }
            else{

                viewAllLawyersButton.innerHTML =
                    `

                        View All ${totalLawyers}
                        Verified Lawyers

                        <i class="fa-solid fa-arrow-right"></i>

                    `;

            }

        }


        /* =====================================================
           RENDER LAWYERS
        ====================================================== */

        function renderLawyers(){

            if(
                !lawyerGrid
            ){

                return;

            }


            const filtered =
                getFilteredLawyers();


            const defaultView =
                isDefaultFilterState();


            let orderedLawyers =
                filtered;


            if(
                defaultView
            ){

                orderedLawyers =
                    getHomepageLawyerOrder();

            }


            let lawyersToDisplay =
                orderedLawyers;


            if(
                defaultView
                &&
                !showAllLawyers
            ){

                lawyersToDisplay =
                    orderedLawyers.slice(
                        0,
                        HOMEPAGE_VISIBLE_LIMIT
                    );

            }


            lawyerGrid.innerHTML =
                "";


            lawyersToDisplay.forEach(
                function(
                    lawyer
                ){

                    lawyerGrid.appendChild(
                        createLawyerCard(
                            lawyer
                        )
                    );

                }
            );


            if(
                resultCount
            ){

                if(
                    defaultView
                ){

                    if(
                        !showAllLawyers
                        &&
                        filtered.length >
                        HOMEPAGE_VISIBLE_LIMIT
                    ){

                        resultCount.textContent =
                            "Showing "
                            +
                            lawyersToDisplay.length
                            +
                            " of "
                            +
                            filtered.length
                            +
                            " verified lawyers";

                    }
                    else{

                        resultCount.textContent =
                            filtered.length ===
                            1

                            ?

                            "1 verified lawyer"

                            :

                            filtered.length
                            +
                            " verified lawyers";

                    }

                }
                else{

                    resultCount.textContent =
                        filtered.length ===
                        1

                        ?

                        "1 lawyer found"

                        :

                        filtered.length
                        +
                        " lawyers found";

                }

            }


            if(
                emptyState
            ){

                emptyState.hidden =
                    filtered.length !==
                    0;

            }


            updateViewAllButton(
                filtered.length,
                defaultView
            );


            attachBookingEvents();

        }


        /* =====================================================
           FILTER CHANGE
        ====================================================== */

        function filterChanged(){

            showAllLawyers =
                false;


            renderLawyers();

        }


        /* =====================================================
           FILTER EVENTS
        ====================================================== */

        if(
            searchInput
        ){

            searchInput.addEventListener(
                "input",
                filterChanged
            );

        }


        if(
            categoryFilter
        ){

            categoryFilter.addEventListener(
                "change",
                filterChanged
            );

        }


        if(
            experienceFilter
        ){

            experienceFilter.addEventListener(
                "change",
                filterChanged
            );

        }


        if(
            feeFilter
        ){

            feeFilter.addEventListener(
                "change",
                filterChanged
            );

        }


        if(
            languageFilter
        ){

            languageFilter.addEventListener(
                "change",
                filterChanged
            );

        }


        if(
            ratingFilter
        ){

            ratingFilter.addEventListener(
                "change",
                filterChanged
            );

        }


        if(
            availabilityFilter
        ){

            availabilityFilter.addEventListener(
                "change",
                filterChanged
            );

        }


        /* =====================================================
           CLEAR FILTERS
        ====================================================== */

        function clearFilters(){

            if(
                searchInput
            ){

                searchInput.value =
                    "";

            }


            if(
                categoryFilter
            ){

                categoryFilter.value =
                    "all";

            }


            if(
                experienceFilter
            ){

                experienceFilter.value =
                    "all";

            }


            if(
                feeFilter
            ){

                feeFilter.value =
                    "all";

            }


            if(
                languageFilter
            ){

                languageFilter.value =
                    "all";

            }


            if(
                ratingFilter
            ){

                ratingFilter.value =
                    "all";

            }


            if(
                availabilityFilter
            ){

                availabilityFilter.value =
                    "all";

            }


            showAllLawyers =
                false;


            renderLawyers();

        }


        if(
            clearFiltersButton
        ){

            clearFiltersButton.addEventListener(
                "click",
                clearFilters
            );

        }


        /* =====================================================
           VIEW ALL / SHOW LESS
        ====================================================== */

        if(
            viewAllLawyersButton
        ){

            viewAllLawyersButton.addEventListener(
                "click",
                function(){

                    showAllLawyers =
                        !showAllLawyers;


                    renderLawyers();


                    if(
                        showAllLawyers
                    ){

                        const cards =
                            lawyerGrid
                                .querySelectorAll(
                                    ".lawyer-card"
                                );


                        if(
                            cards[
                                HOMEPAGE_VISIBLE_LIMIT
                            ]
                        ){

                            cards[
                                HOMEPAGE_VISIBLE_LIMIT
                            ]
                            .scrollIntoView({

                                behavior:
                                    "smooth",

                                block:
                                    "start"

                            });

                        }

                    }
                    else{

                        const lawyerSection =
                            document.querySelector(
                                "#lawyers"
                            );


                        if(
                            lawyerSection
                        ){

                            lawyerSection
                                .scrollIntoView({

                                    behavior:
                                        "smooth",

                                    block:
                                        "start"

                                });

                        }

                    }

                }
            );

        }


        /* =====================================================
           PRACTICE AREA BUTTONS
        ====================================================== */

        document
            .querySelectorAll(
                ".view-lawyers-btn"
            )
            .forEach(
                function(
                    button
                ){

                    button.addEventListener(
                        "click",
                        function(){

                            const category =
                                button.dataset
                                    .category;


                            if(
                                categoryFilter
                            ){

                                categoryFilter.value =
                                    category;

                            }


                            showAllLawyers =
                                false;


                            renderLawyers();


                            const lawyerSection =
                                document.querySelector(
                                    "#lawyers"
                                );


                            if(
                                lawyerSection
                            ){

                                lawyerSection
                                    .scrollIntoView({

                                        behavior:
                                            "smooth",

                                        block:
                                            "start"

                                    });

                            }

                        }
                    );

                }
            );


        /* =====================================================
           HERO BUTTONS
        ====================================================== */

        const primaryButton =
            document.querySelector(
                ".primary-btn"
            );


        const secondaryButton =
            document.querySelector(
                ".secondary-btn"
            );


        function scrollToLawyers(){

            const lawyerSection =
                document.querySelector(
                    "#lawyers"
                );


            if(
                lawyerSection
            ){

                lawyerSection
                    .scrollIntoView({

                        behavior:
                            "smooth",

                        block:
                            "start"

                    });

            }

        }


        if(
            primaryButton
        ){

            primaryButton.addEventListener(
                "click",
                scrollToLawyers
            );

        }


        if(
            secondaryButton
        ){

            secondaryButton.addEventListener(
                "click",
                function(e){
                    e.preventDefault();
                    const lawyerSec = document.querySelector("#lawyers");
                    if(lawyerSec){
                        lawyerSec.scrollIntoView({ behavior: "smooth" });
                        setTimeout(function(){
                            const firstBtn = lawyerSec.querySelector(".book-lawyer-btn");
                            if(firstBtn){
                                firstBtn.focus();
                            }
                        }, 400);
                    } else {
                        window.location.href = "booking.html";
                    }
                }
            );

        }


        /* =====================================================
           BOOKING FLOW & EVENTS
        ====================================================== */

        function triggerLawyerBooking(lawyerId, databaseId, cardElement){

            let lawyer = null;

            if(lawyerId || databaseId){
                lawyer =
                    lawyers.find(
                        item =>
                            String(item.id) === String(lawyerId) ||
                            String(item.directoryId) === String(lawyerId) ||
                            String(item.databaseId) === String(lawyerId) ||
                            (item.legacy_id && String(item.legacy_id) === String(lawyerId)) ||
                            (databaseId && String(item.databaseId) === String(databaseId)) ||
                            (databaseId && String(item.directoryId) === String(databaseId))
                    );
            }

            if(!lawyer && cardElement){
                const nameEl = cardElement.querySelector("h3");
                const feeEl = cardElement.querySelector(".consultation-fee strong");
                const specEl = cardElement.querySelector(".lawyer-specialization");
                const imgEl = cardElement.querySelector(".lawyer-profile-image");
                if(nameEl){
                    const name = nameEl.textContent.trim();
                    const found = lawyers.find(l => l.name === name);
                    if(found){
                        lawyer = found;
                    } else {
                        lawyer = {
                            id: lawyerId || "d0000000-0000-4000-b000-000000000000",
                            databaseId: databaseId || "d0000000-0000-4000-b000-000000000001",
                            name: name,
                            category: specEl ? specEl.textContent.toLowerCase().replace("specialist", "").trim() : "criminal",
                            fee: feeEl ? (Number(feeEl.textContent.replace(/[^\d]/g, "")) || 1) : 1,
                            image: imgEl ? imgEl.src : "",
                            source: "directory",
                            bookable: true
                        };
                    }
                }
            }

            if(!lawyer){
                lawyer = lawyers[0] || {
                    id: "d0000000-0000-4000-b000-000000000000",
                    databaseId: "d0000000-0000-4000-b000-000000000001",
                    name: "Adv. Tanvi Patil",
                    category: "criminal",
                    fee: 1,
                    source: "directory",
                    bookable: true
                };
            }

            const resolvedDatabaseId = (function(){
                const rawId = lawyer.databaseId || lawyer.genuineLinkedUserId || lawyer.testRouteUserId || (databaseId && databaseId !== "undefined" ? databaseId : null);
                if (rawId) {
                    const stripped = String(rawId).replace(/^(supabase-|lawyer-user-|client-user-|demo-user-)/i, "");
                    // Check if the stripped version is a valid UUID
                    if (/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(stripped)) {
                        return stripped;
                    }
                    if (rawId && !String(rawId).includes("-user-") && !String(rawId).includes("supabase-") && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(rawId)) {
                        return rawId;
                    }
                }
                
                // Fallback to legacy padding for numeric IDs
                const numericId = (lawyer.legacy_id || lawyer.id || databaseId || "1");
                const match = String(numericId).match(/\d+/);
                const num = match ? match[0] : "1";
                return "d0000000-0000-4000-b000-" + String(num).padStart(12, '0');
            })();

            lawyer.databaseId = resolvedDatabaseId;
            lawyer.bookable = true;

            sessionStorage.setItem(
                "selectedLawyer",
                JSON.stringify(
                    lawyer
                )
            );

            sessionStorage.setItem(
                "selectedLawyerId",
                String(resolvedDatabaseId)
            );

            sessionStorage.setItem(
                "selectedLawyerName",
                lawyer.name
            );

            sessionStorage.setItem(
                "selectedLawyerCategory",
                lawyer.category
            );

            sessionStorage.setItem(
                "selectedLawyerFee",
                String(
                    lawyer.fee
                )
            );

            sessionStorage.setItem(
                "selectedLawyerImage",
                lawyer.image || ""
            );

            sessionStorage.setItem(
                "selectedLawyerSource",
                lawyer.source
                ||
                "directory"
            );

            window.location.href =
                "booking.html";

        }

        function attachBookingEvents(){
            // Delegated click listener below handles all .book-lawyer-btn elements reliably
        }

        /* Global delegated booking listener ensures cards in ALL sections and dynamic filters always work */
        document.addEventListener("click", function(event){
            const button = event.target.closest(".book-lawyer-btn");
            if(button){
                event.preventDefault();
                event.stopPropagation();
                const card = button.closest(".lawyer-card");
                triggerLawyerBooking(
                    button.dataset.lawyerId,
                    button.dataset.databaseId,
                    card
                );
            }
        });
                /* =====================================================
           LOGIN
        ====================================================== */

        const loginButton =
            document.querySelector(
                ".login-btn"
            );


        if(
            loginButton
        ){

            loginButton.addEventListener(
                "click",
                function(){

                    window.location.href =
                        "login.html?role=client";

                }
            );

        }


        /* =====================================================
           REGISTER
        ====================================================== */

        const registerButton =
            document.querySelector(
                ".register-btn"
            );


        if(
            registerButton
        ){

            registerButton.addEventListener(
                "click",
                function(){

                    window.location.href =
                        "login.html";

                }
            );

        }


        /* =====================================================
           NAVBAR SCROLL SHADOW
        ====================================================== */

        const header =
            document.querySelector(
                ".header"
            );


        window.addEventListener(
            "scroll",
            function(){

                if(
                    !header
                ){

                    return;

                }


                header.style.boxShadow =

                    window.scrollY >
                    20

                    ?

                    "0 10px 35px rgba(0,0,0,.11)"

                    :

                    "0 10px 35px rgba(0,0,0,.06)";

            }
        );


        /* =====================================================
           LIVE LAWYER DIRECTORY REFRESH

           Keeps the visible Lawyer count and cards synchronized
           when Lawyers are approved, activated, deactivated,
           edited or newly added in Supabase.
        ====================================================== */

        let lawyerRealtimeChannel =
            null;


        let lawyerRefreshTimer =
            null;


        let lawyerRefreshPromise =
            null;


        async function refreshLawyerDirectory(){

            if(
                lawyerRefreshPromise
            ){

                return lawyerRefreshPromise;

            }


            lawyerRefreshPromise =
                (async function(){

                    lawyers.length =
                        0;


                    await loadDirectorySupabaseLawyers();


                    await loadApprovedSupabaseLawyers();


                    updateCategoryCounts();


                    renderLawyers();


                    console.log(
                        "Live verified Lawyer count:",
                        lawyers.length
                    );

                })()
                .catch(
                    function(error){

                        console.error(
                            "NyayaSetu live Lawyer refresh error:",
                            error
                        );

                    }
                )
                .finally(
                    function(){

                        lawyerRefreshPromise =
                            null;

                    }
                );


            return lawyerRefreshPromise;

        }


        function scheduleLawyerDirectoryRefresh(){

            if(
                lawyerRefreshTimer
            ){

                clearTimeout(
                    lawyerRefreshTimer
                );

            }


            lawyerRefreshTimer =
                setTimeout(
                    async function(){

                        lawyerRefreshTimer =
                            null;


                        await refreshLawyerDirectory();

                    },
                    350
                );

        }


        function setupLawyerRealtime(){

            const supabase =
                window.NyayaSetuSupabase;


            if(
                !supabase
                ||
                typeof supabase.channel !==
                    "function"
            ){

                return;

            }


            if(
                lawyerRealtimeChannel
            ){

                supabase.removeChannel(
                    lawyerRealtimeChannel
                );

            }


            lawyerRealtimeChannel =
                supabase
                    .channel(
                        "public-lawyer-directory-live"
                    )
                    .on(
                        "postgres_changes",
                        {
                            event:"*",
                            schema:"public",
                            table:"lawyer_profiles"
                        },
                        scheduleLawyerDirectoryRefresh
                    )
                    .on(
                        "postgres_changes",
                        {
                            event:"*",
                            schema:"public",
                            table:"lawyer_directory_profiles"
                        },
                        scheduleLawyerDirectoryRefresh
                    )
                    .subscribe();

        }


        window.addEventListener(
            "focus",
            scheduleLawyerDirectoryRefresh
        );


        document.addEventListener(
            "visibilitychange",
            function(){

                if(
                    document.visibilityState ===
                    "visible"
                ){

                    scheduleLawyerDirectoryRefresh();

                }

            }
        );


        /* =====================================================
           INITIAL PAGE LOAD
        ====================================================== */

        async function initializeLawyerDirectory(){

            try{

                /*
                    Load the current complete Lawyer directory.
                    This includes all directory profiles plus every
                    APPROVED + ACTIVE real Lawyer as a separate card.
                */

                await refreshLawyerDirectory();


                /*
                    Keep the directory synchronized in realtime so
                    the visible total automatically moves from
                    49 -> 50 -> 51 ... as new Lawyers are approved.
                */

                setupLawyerRealtime();


                console.log(
                    "NYAYSETU loaded successfully."
                );


                console.log(
                    "Total verified lawyers:",
                    lawyers.length
                );


                console.log(
                    "Bookable real lawyers:",
                    lawyers.filter(
                        lawyer =>
                            lawyer.bookable
                    ).length
                );


                console.log(
                    "Homepage lawyers initially visible:",
                    Math.min(
                        HOMEPAGE_VISIBLE_LIMIT,
                        lawyers.length
                    )
                );

            }
            catch(error){

                console.error(
                    "NyayaSetu Lawyer directory initialization error:",
                    error
                );


                if(
                    lawyerGrid
                ){

                    lawyerGrid.innerHTML =
                        `
                            <div class="lawyer-empty">
                                <i class="fa-solid fa-circle-exclamation"></i>
                                <h3>Unable to load lawyers</h3>
                                <p>Please refresh the page and try again.</p>
                            </div>
                        `;

                }


                if(
                    resultCount
                ){

                    resultCount.textContent =
                        "Lawyer directory unavailable";

                }

            }

        }


        initializeLawyerDirectory();

    }
);