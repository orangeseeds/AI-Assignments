// tree_structure is defined in js/data.js


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
        HTMLclass: "winner",
    }
};
function main(json) {
    tree = new Treant(json);

}

let timer = {
    index: 1,
    delay: 10, // in ms
}

var importObject = {
    env: {
        addChild: function(parentId, childId, cannibals, missionaries, state) {
            console.log("data", parentId, childId, cannibals, missionaries, state)
            setTimeout(() => {
                if (childId === 1) {
                    wasmTree.nodeStructure.text.id = childId
                    wasmTree.nodeStructure.text.name = `${cannibals}C ${missionaries}M ${state}`
                    tree.reload()
                    return;
                }
                else if (parentId == 1) {
                    wasmTree.nodeStructure.children.push(
                        {
                            text: {
                                id: childId,
                                name: `${cannibals}C ${missionaries}M ${state}`,
                                desc: `${childId}`,
                            },
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
                                name: `${cannibals}C ${missionaries}M ${state}`,
                                desc: `${childId}`,
                            },
                            children: [],
                        }
                    );

                }

                console.log(wasmTree.nodeStructure)
                tree.reload()
            }, timer.delay * timer.index)
            timer.index = timer.index + 1
        },

    },
};

function findNodeById(tree, targetId) {
    if (!tree || typeof tree !== 'object') {
        // console.log("here")
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

    // console.log("here null")
    return null;
}

WebAssembly.instantiateStreaming(fetch("./wasm/wasm.wasm"), importObject).then((result) => {
    // const wasmMemoryArray = new Uint8Array(memory.buffer);
    //
    window.addEventListener("click", () => {
        findNodeById(tree_structure.nodeStructure, 14).text.name = "Apple";
        tree.reload();
    })
    main(wasmTree);

    var instance = result.instance;
    var data = instance.exports.sendChild(100)
    console.log(data)

    const container = document.getElementById("treeChart");
    // make an element as large as an image inside it
    container.style.width = "100vw";
    container.style.height = "100vh";
}).catch(err => {
    console.log(err);
})

