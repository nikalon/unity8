/*
 * Copyright 2013 Canonical Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import QtTest 1.0
import Unity 0.2
import ".."
import "../../../qml/Dash"
import "../../../qml/Components"
import Ubuntu.Components 0.1
import Unity.Test 0.1 as UT

Item {
    id: shell
    width: units.gu(120)
    height: units.gu(100)

    // TODO Add a test that checks we don't preview things whose uri starts with scope://

    // BEGIN To reduce warnings
    // TODO I think it we should pass down these variables
    // as needed instead of hoping they will be globally around
    property var greeter: null
    property var panel: null
    // BEGIN To reduce warnings

    Scopes {
        id: scopes
        // for tryGenericScopeView
        onLoadedChanged: if (loaded) genericScopeView.scope = scopes.getScope(2);
    }

    SignalSpy {
        id: spy
    }

    property Item applicationManager: Item {
        signal sideStageFocusedApplicationChanged()
        signal mainStageFocusedApplicationChanged()
    }

    GenericScopeView {
        id: genericScopeView
        anchors.fill: parent

        UT.UnityTestCase {
            id: testCase
            name: "GenericScopeView"
            when: scopes.loaded && windowShown

            property Item subPageLoader: findChild(genericScopeView, "subPageLoader")
            property Item header: findChild(genericScopeView, "scopePageHeader")

            function init() {
                genericScopeView.scope = scopes.getScope(2);
                shell.width = units.gu(120);
                genericScopeView.categoryView.positionAtBeginning();
                waitForRendering(genericScopeView.categoryView);
            }

            function cleanup() {
                genericScopeView.scope = null;
                spy.clear();
                spy.target = null;
                spy.signalName = "";
            }

            function scrollToCategory(category) {
                var categoryListView = findChild(genericScopeView, "categoryListView");
                tryCompareFunction(function() {
                    if (findChild(genericScopeView, category)) return true;
                    mouseFlick(genericScopeView, genericScopeView.width/2, genericScopeView.height,
                               genericScopeView.width/2, genericScopeView.y)
                    tryCompare(categoryListView, "moving", false);
                    return findChild(genericScopeView, category) !== null;
                }, true);

                tryCompareFunction(function() { return findChild(genericScopeView, "delegate0") !== null; }, true);
                return findChild(genericScopeView, category);
            }

            function test_isActive() {
                tryCompare(genericScopeView.scope, "isActive", false)
                genericScopeView.isCurrent = true
                tryCompare(genericScopeView.scope, "isActive", true)
                testCase.subPageLoader.open = true
                tryCompare(genericScopeView.scope, "isActive", false)
                testCase.subPageLoader.open = false
                tryCompare(genericScopeView.scope, "isActive", true)
                genericScopeView.isCurrent = false
                tryCompare(genericScopeView.scope, "isActive", false)
            }

            function test_showDash() {
                testCase.subPageLoader.open = true;
                genericScopeView.scope.showDash();
                tryCompare(testCase.subPageLoader, "open", false);
            }

            function test_hideDash() {
                testCase.subPageLoader.open = true;
                genericScopeView.scope.hideDash();
                tryCompare(testCase.subPageLoader, "open", false);
            }

            function test_searchQuery() {
                genericScopeView.scope = scopes.getScope(0);
                genericScopeView.scope.searchQuery = "test";
                genericScopeView.scope = scopes.getScope(1);
                genericScopeView.scope.searchQuery = "test2";
                genericScopeView.scope = scopes.getScope(0);
                tryCompare(genericScopeView.scope, "searchQuery", "test");
                genericScopeView.scope = scopes.getScope(1);
                tryCompare(genericScopeView.scope, "searchQuery", "test2");
            }

            function test_changeScope() {
                genericScopeView.scope.searchQuery = "test"
                var originalScopeId = genericScopeView.scope.id;
                genericScopeView.scope = scopes.getScope(originalScopeId + 1)
                genericScopeView.scope = scopes.getScope(originalScopeId)
                tryCompare(genericScopeView.scope, "searchQuery", "test")
            }

            function test_expand_collapse() {
                tryCompareFunction(function() { return findChild(genericScopeView, "dashSectionHeader0") != null; }, true);

                var category = findChild(genericScopeView, "dashCategory0")
                var seeAll = findChild(category, "seeAll")

                waitForRendering(seeAll);
                verify(category.expandable);
                verify(!category.expanded);

                var initialHeight = category.height;
                mouseClick(seeAll, seeAll.width / 2, seeAll.height / 2);
                verify(category.expanded);
                tryCompare(category, "height", category.item.expandedHeight + seeAll.height);

                waitForRendering(seeAll);
                mouseClick(seeAll, seeAll.width / 2, seeAll.height / 2);
                verify(!category.expanded);
            }

            function test_expand_expand_collapse() {
                // wait for the item to be there
                tryCompareFunction(function() { return findChild(genericScopeView, "dashSectionHeader2") != null; }, true);

                var categoryListView = findChild(genericScopeView, "categoryListView");
                categoryListView.contentY = categoryListView.height;

                var category2 = findChild(genericScopeView, "dashCategory2")
                var seeAll2 = findChild(category2, "seeAll")

                waitForRendering(seeAll2);
                verify(category2.expandable);
                verify(!category2.expanded);

                mouseClick(seeAll2, seeAll2.width / 2, seeAll2.height / 2);
                tryCompare(category2, "expanded", true);

                categoryListView.positionAtBeginning();

                var category0 = findChild(genericScopeView, "dashCategory0")
                var seeAll0 = findChild(category0, "seeAll")
                mouseClick(seeAll0, seeAll0.width / 2, seeAll0.height / 2);
                tryCompare(category0, "expanded", true);
                tryCompare(category2, "expanded", false);
                mouseClick(seeAll0, seeAll0.width / 2, seeAll0.height / 2);
                tryCompare(category0, "expanded", false);
                tryCompare(category2, "expanded", false);
            }

            function test_headerLink() {
                tryCompareFunction(function() { return findChild(genericScopeView, "dashSectionHeader1") != null; }, true);
                var header = findChild(genericScopeView, "dashSectionHeader1");

                spy.target = genericScopeView.scope;
                spy.signalName = "performQuery";

                mouseClick(header, header.width / 2, header.height / 2);

                spy.wait();
                compare(spy.signalArguments[0][0], genericScopeView.scope.categories.data(1, Categories.RoleHeaderLink));
            }

            function test_headerLink_disable_expansion() {
                var categoryListView = findChild(genericScopeView, "categoryListView");
                waitForRendering(categoryListView);

                categoryListView.contentY = categoryListView.height * 2;

                // wait for the item to be there
                tryCompareFunction(function() { return findChild(genericScopeView, "dashSectionHeader4") != null; }, true);

                var categoryView = findChild(genericScopeView, "dashCategory4");
                verify(categoryView, "Can't find the category view.");

                var seeAll = findChild(categoryView, "seeAll");
                verify(seeAll, "Can't find the seeAll element");

                compare(seeAll.height, 0, "SeeAll should be 0-height.");

                openPreview(4, 0);

                compare(testCase.subPageLoader.count, 12, "There should only be 12 items in preview.");

                closePreview();
            }

            function test_narrow_delegate_ranges_expand() {
                tryCompareFunction(function() { return findChild(genericScopeView, "dashCategory0") !== null; }, true);
                var category = findChild(genericScopeView, "dashCategory0")
                tryCompare(category, "expanded", false);

                shell.width = units.gu(20)
                var categoryListView = findChild(genericScopeView, "categoryListView");
                categoryListView.contentY = units.gu(20);
                var seeAll = findChild(category, "seeAll")
                mouseClick(seeAll, seeAll.width / 2, seeAll.height / 2);
                tryCompare(category, "expanded", true);
                tryCompareFunction(function() { return category.item.height == genericScopeView.height - category.item.displayMarginBeginning - category.item.displayMarginEnd; }, true);
                mouseClick(seeAll, seeAll.width / 2, seeAll.height / 2);
                tryCompare(category, "expanded", false);
            }

            function test_forced_category_expansion() {
                var category = scrollToCategory("dashCategory19");
                compare(category.expandable, false, "Category with collapsed-rows: 0 should not be expandable");

                var grid = findChild(category, "19");
                verify(grid, "Could not find the category renderer.");

                compare(grid.height, grid.expandedHeight, "Category with collapsed-rows: 0 should always be expanded.");
            }

            function test_single_category_expansion() {
                genericScopeView.scope = scopes.getScope(3);

                tryCompareFunction(function() { return findChild(genericScopeView, "dashCategory0") != undefined; }, true);
                var category = findChild(genericScopeView, "dashCategory0")
                compare(category.expandable, false, "Only category should not be expandable.");

                var grid = findChild(category, "0");
                verify(grid, "Could not find the category renderer.");

                compare(grid.height, grid.expandedHeight, "Only category should always be expanded");
            }

            function openPreview(category, delegate) {
                if (category === undefined) category = 0;
                if (delegate === undefined) delegate = 0;
                tryCompareFunction(function() {
                                        var cardGrid = findChild(genericScopeView, category);
                                        if (cardGrid != null) {
                                            var tile = findChild(cardGrid, "delegate"+delegate);
                                            return tile != null;
                                        }
                                        return false;
                                    },
                                    true);
                var tile = findChild(findChild(genericScopeView, category), "delegate"+delegate);
                mouseClick(tile, tile.width / 2, tile.height / 2);
                tryCompare(testCase.subPageLoader, "open", true);
                tryCompare(testCase.subPageLoader, "x", 0);
            }

            function closePreview() {
                var closePreviewMouseArea = findChild(subPageLoader.item, "pageHeader");
                mouseClick(closePreviewMouseArea, units.gu(2), units.gu(2));

                tryCompare(testCase.subPageLoader, "open", false);
            }

            function test_previewOpenClose() {
                tryCompare(testCase.subPageLoader, "open", false);

                var categoryListView = findChild(genericScopeView, "categoryListView");
                categoryListView.positionAtBeginning();

                openPreview();
                closePreview();
            }

            function test_showPreviewCarousel() {
                var category = scrollToCategory("dashCategory1");

                tryCompare(testCase.subPageLoader, "open", false);

                var tile = findChild(category, "carouselDelegate1");
                verify(tile, "Could not find delegate");

                mouseClick(tile, tile.width / 2, tile.height / 2);
                tryCompare(tile, "explicitlyScaled", true);
                mouseClick(tile, tile.width / 2, tile.height / 2);
                tryCompare(testCase.subPageLoader, "open", true);
                tryCompare(testCase.subPageLoader, "x", 0);

                closePreview();

                mousePress(tile, tile.width / 2, tile.height / 2);
                tryCompare(testCase.subPageLoader, "open", true);
                tryCompare(testCase.subPageLoader, "x", 0);
                mouseRelease(tile, tile.width / 2, tile.height / 2);

                closePreview();
            }

            function test_showPreviewHorizontalList() {
                var category = scrollToCategory("dashCategory18");

                tryCompare(testCase.subPageLoader, "open", false);

                var tile = findChild(category, "delegate1");
                verify(tile, "Could not find delegate");

                mouseClick(tile, tile.width / 2, tile.height / 2);
                tryCompare(testCase.subPageLoader, "open", true);
                tryCompare(testCase.subPageLoader, "x", 0);

                closePreview();

                mousePress(tile, tile.width / 2, tile.height / 2);
                tryCompare(testCase.subPageLoader, "open", true);
                tryCompare(testCase.subPageLoader, "x", 0);
                mouseRelease(tile, tile.width / 2, tile.height / 2);

                closePreview();
            }

            function test_previewCycle() {
                var categoryListView = findChild(genericScopeView, "categoryListView");
                categoryListView.positionAtBeginning();

                tryCompare(testCase.subPageLoader, "open", false);

                openPreview();
                var previewListViewList = findChild(subPageLoader.item, "listView");

                // flick to the next previews
                tryCompare(testCase.subPageLoader, "count", 15);
                for (var i = 1; i < testCase.subPageLoader.count; ++i) {
                    mouseFlick(testCase.subPageLoader.item, testCase.subPageLoader.width - units.gu(1),
                                                testCase.subPageLoader.height / 2,
                                                units.gu(2),
                                                testCase.subPageLoader.height / 2);
                    tryCompare(previewListViewList, "moving", false);
                    tryCompare(testCase.subPageLoader.currentItem, "objectName", "preview" + i);
                }
                closePreview();
            }

            function test_settingsOpenClose() {
                waitForRendering(genericScopeView);
                verify(header, "Could not find the header.");
                var innerHeader = findChild(header, "innerPageHeader");
                verify(innerHeader, "Could not find the inner header");

                // open
                tryCompare(testCase.subPageLoader, "open", false);
                var settings = findChild(innerHeader, "settings_header_button");
                mouseClick(settings, settings.width / 2, settings.height / 2);
                tryCompare(testCase.subPageLoader, "open", true);
                verify(("" + subPageLoader.source).indexOf("ScopeSettingsPage.qml") != -1);
                compare(genericScopeView.settingsShown, true)
                tryCompare(testCase.subPageLoader, "x", 0);

                // close
                var settingsHeader = findChild(testCase.subPageLoader.item, "pageHeader");
                mouseClick(settingsHeader, units.gu(2), units.gu(2));
                tryCompare(testCase.subPageLoader, "open", false);
                compare(genericScopeView.settingsShown, false);
                var categoryListView = findChild(genericScopeView, "categoryListView");
                tryCompare(categoryListView, "x", 0);
            }

            function test_header_style_data() {
                return [
                    { tag: "Default", index: 0, foreground: "grey", background: "", logo: "" },
                    { tag: "Foreground", index: 1, foreground: "yellow", background: "", logo: "" },
                    { tag: "Logo+Background", index: 2, foreground: "grey", background: "gradient:///lightgrey/grey",
                      logo: Qt.resolvedUrl("../Components/tst_PageHeader/logo-ubuntu-orange.svg") },
                ];
            }

            function test_header_style(data) {
                genericScopeView.scope = scopes.getScope(data.index);
                waitForRendering(genericScopeView);
                verify(header, "Could not find the header.");

                var innerHeader = findChild(header, "innerPageHeader");
                verify(innerHeader, "Could not find the inner header");
                verify(Qt.colorEqual(innerHeader.textColor, data.foreground),
                       "Foreground color not equal: %1 != %2".arg(innerHeader.textColor).arg(data.foreground));

                var background = findChild(header, "headerBackground");
                verify(background, "Could not find the background");
                compare(background.style, data.background);

                var image = findChild(genericScopeView, "titleImage");
                if (data.logo == "") expectFail(data.tag, "Title image should not exist.");
                verify(image, "Could not find the title image.");
                compare(image.source, data.logo, "Title image has the wrong source");
            }
        }
    }
}
