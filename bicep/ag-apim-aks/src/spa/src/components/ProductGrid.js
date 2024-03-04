import React, { useState, useEffect } from 'react'
import { getProducts } from '../productService';
import MaterialTable from "material-table";
import tableIcons from "./MaterialTableIcons";
import { useMsal } from "@azure/msal-react";
import { productApi } from "../authConfig";

const columns = [
    { field: 'ID', title: 'ID', type: "numeric" },
    { field: 'Name', title: 'Name' },
    { field: 'Description', title: 'Description' }
]

export const ProductGrid = () => {
    const { instance, accounts } = useMsal();
    const [tableData, setTableData] = useState([])

    useEffect(() => {
        instance.acquireTokenSilent({
            ...productApi,
            account: accounts[0]
        }).then((response) => {
            let accessToken = response.accessToken;
            getProducts(accessToken)
            .catch(error => console.log(error), (data = '[]') => setTableData(data))
                .then((data) => setTableData(data));
        })
    }, [])

    const handleRowUpdate = (newData, oldData, resolve) => {
        //validation
        let errorList = []
        if (newData.Name === "") {
            errorList.push("Please enter order name")
        }
        if (newData.Description === "") {
            errorList.push("Please enter order description")
        }

        if (errorList.length < 1) {
            api.patch("/users/" + newData.id, newData)
                .then(res => {
                    const dataUpdate = [...data];
                    const index = oldData.tableData.id;
                    dataUpdate[index] = newData;
                    setData([...dataUpdate]);
                    resolve()
                    setIserror(false)
                    setErrorMessages([])
                })
                .catch(error => {
                    setErrorMessages(["Update failed! Server error"])
                    setIserror(true)
                    resolve()
                })
        } else {
            setErrorMessages(errorList)
            setIserror(true)
            resolve()
        }
    }

    const handleRowAdd = (newData, resolve) => {
        //validation
        let errorList = []
        if (newData.Name === undefined) {
            errorList.push("Please enter first name")
        }
        if (newData.Description === undefined) {
            errorList.push("Please enter last name")
        }
        if (errorList.length < 1) { //no error
            api.post("/users", newData)
                .then(res => {
                    let dataToAdd = [...data];
                    dataToAdd.push(newData);
                    setData(dataToAdd);
                    resolve()
                    setErrorMessages([])
                    setIserror(false)
                })
                .catch(error => {
                    setErrorMessages(["Cannot add data. Server error!"])
                    setIserror(true)
                    resolve()
                })
        } else {
            setErrorMessages(errorList)
            setIserror(true)
            resolve()
        }
    }

    const handleRowDelete = (oldData, resolve) => {

        api.delete("/users/" + oldData.id)
            .then(res => {
                const dataDelete = [...data];
                const index = oldData.tableData.id;
                dataDelete.splice(index, 1);
                setData([...dataDelete]);
                resolve()
            })
            .catch(error => {
                setErrorMessages(["Delete failed! Server error"])
                setIserror(true)
                resolve()
            })
    }

    console.log("tableData: " + tableData)
    
    return (
        <div style={{ height: 500, width: '90%', margin: 'auto' }}>
            <MaterialTable
                title="Products"
                columns={columns}
                data={tableData}
                icons={tableIcons}
            /*                 editable={{
                    onRowUpdate: (newData, oldData) =>
                        new Promise((resolve) => {
                            handleRowUpdate(newData, oldData, resolve);
                        }),
                    onRowAdd: (newData) =>
                        new Promise((resolve) => {
                            handleRowAdd(newData, resolve)
                        }),
                    onRowDelete: (oldData) =>
                        new Promise((resolve) => {
                            handleRowDelete(oldData, resolve)
                        }),
                }} */
            />
        </div>
    )
}