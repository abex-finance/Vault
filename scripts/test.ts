async function main() {

}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(`error: ${error.stack}`);
        process.exit(1);
    });