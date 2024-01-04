// tree_structure is defined in js/data.js

const slider = document.getElementById("mySlider");
const sliderValueDisplay = document.getElementById("sliderValue");

let sliderValue = slider.value;

slider.addEventListener("input", () => {
    sliderValue = slider.value;
    sliderValue = Number(sliderValue) * 20;
    timer.delay = sliderValue;

    sliderValueDisplay.textContent = sliderValue;
});

var tree;
var wasmTree = {

    chart: {
        container: "#treeChart",
        levelSeparation: 20,
        siblingSeparation: 15,
        subTeeSeparation: 15,
        rootOrientation: "WEST",

        node: {
            HTMLclass: "tennis-draw",
            drawLineThrough: true
        },
        connectors: {
            type: "straight",
            style: {
                "stroke-width": 2,
                "stroke": "#ccc"
            }
        }
    },

    nodeStructure: {
        text: {
            id: 1,
            name: "3C 3M 1",
            desc: "start node",
        },
        children: [],
        HTMLclass: "start",
    }
};
function main(json) {
    tree = new Treant(json);
}

let timer = {
    index: 1,
    delay: 400, // in ms
}
function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

var importObject = {
    env: {
        addChild: function(parentId, childId, row, col, misplaced, status) {
            // console.log(status)

            // StateType.Start => 0,
            // StateType.Goal => 1,
            // StateType.Duplicate => 2,
            // StateType.NoContinue => 3,
            // StateType.Invalid => 4,
            // StateType.NoType => 5,
            //
            let className = "";
            switch (status) {
                case 0:
                    className = "start";
                    break;
                case 1:
                    className = "goal";
                    break;
                case 2:
                    className = "duplicate";
                    break;
                case 3:
                    className = "no-continue";
                    break;
                case 4:
                    className = "invalid";
                    break;
                default:
                    className = "no-type";
                    break;
            }

            if (childId === 1) {
                wasmTree.nodeStructure.text.id = childId
                wasmTree.nodeStructure.text.name = `${row}R ${col}C ${misplaced}H`
                tree.reload()
                return;
            }
            else if (parentId == 1) {
                wasmTree.nodeStructure.children.push(
                    {
                        text: {
                            id: childId,
                            name: `${row}R ${col}C ${misplaced}H`,
                            desc: `${childId}`,
                        },

                        HTMLclass: className,
                        children: [],
                    }
                )
                tree.reload()
                return;
            }

            let node = findNodeById(wasmTree.nodeStructure, parentId)
            if (node && node.children) {
                node.children.push(
                    {
                        text: {
                            id: childId,
                            name: `${row}R ${col}C ${misplaced}H`,
                            desc: `${childId}`,
                        },

                        HTMLclass: className,
                        children: [],
                    }
                );

            }

            // console.log(wasmTree.nodeStructure)
            tree.reload()
            window.scrollTo(0, document.body.scrollHeight);
        },

    },
};

function findNodeById(tree, targetId) {
    if (!tree || typeof tree !== 'object') {
        return null;
    }

    if (tree.text && tree.text.id === targetId) {
        return tree;
    }

    if (Array.isArray(tree.children)) {
        for (const child of tree.children) {
            const foundNode = findNodeById(child, targetId);
            if (foundNode) {
                return foundNode;
            }
        }
    }

    return null;
}

async function run(callback) {
    let next = 1;
    while (next != 0) {
        await sleep(timer.delay);
        next = callback()
    }
}

WebAssembly.instantiateStreaming(fetch("./wasm/wasm-eight.wasm"), importObject).then(async (result) => {
    // const wasmMemoryArray = new Uint8Array(memory.buffer);
    //
    window.addEventListener("click", () => {
        findNodeById(tree_structure.nodeStructure, 14).text.name = "Apple";
        tree.reload();
    })
    main(wasmTree);

    var instance = result.instance;
    var data = instance.exports.dfsSetup(100)
    // var data = instance.exports.sendChild(100)

    let next = instance.exports.dfsNext


    const container = document.getElementById("container");
    // const content = document.getElementById("treeChart");
    // make an element as large as an image inside it
    container.style.overflow = "hidden";
    content.style.overflow = "hidden";
    content.style.width = "auto";
    content.style.height = "auto";
    container.style.width = "auto";
    container.style.height = "auto";
    container.style.minHeight = "100vh";
    container.style.display = "flex";

    container.style.justifyContent = "center";
    container.style.alignItems = "center";
    // container.style.overflowX = "auto";
    // container.style.overflowY = "auto";

    await run(next);
}).catch(err => {
    console.log(err);
})

