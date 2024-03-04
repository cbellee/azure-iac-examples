package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"strconv"

	"github.com/gorilla/mux"
	log "github.com/sirupsen/logrus"

	"github.com/jinzhu/gorm"
	_ "github.com/jinzhu/gorm/dialects/mssql"
	_ "github.com/jinzhu/gorm/dialects/sqlite"
	"github.com/rs/cors"
)

var dbCxn string = os.Getenv("DB_CXN")
var db, _ = gorm.Open("mssql", dbCxn)

func initDB(cxn string) *gorm.DB {
	db, err := gorm.Open("mssql", cxn)
	if err != nil {
		log.Panic(err)
	}
	return db
}

type TodoItemEntity struct {
	gorm.Model
	Description string `json:"description"`
	Completed   bool   `json:"completed"`
}

type CreateOrUpdateTodoItem struct {
	Description string `json:"description"`
}

type CompleteTodoItem struct {
	Completed bool `json:"completed"`
}

// main entry point
func main() {
	defer db.Close()

	db.Debug().AutoMigrate(&TodoItemEntity{})

	funcPrefix := "/api"
	listenAddr := ":8080"

	if val, ok := os.LookupEnv("FUNCTIONS_CUSTOMHANDLER_PORT"); ok {
		listenAddr = ":" + val
	}

	log.Info("Starting ToDoList API Server")

	router := mux.NewRouter()
	router.HandleFunc(fmt.Sprintf("%s/healthz", funcPrefix), healthz).Methods("GET")
	router.HandleFunc(fmt.Sprintf("%s/todos", funcPrefix), get).Methods("GET")
	router.HandleFunc(fmt.Sprintf("%s/todos/completed", funcPrefix), getCompleted).Methods("GET")
	router.HandleFunc(fmt.Sprintf("%s/todos/incomplete", funcPrefix), getIncomplete).Methods("GET")
	router.HandleFunc(fmt.Sprintf("%s/todos", funcPrefix), create).Methods("POST")
	router.HandleFunc(fmt.Sprintf("%s/todos/{id}", funcPrefix), update).Methods("PATCH")
	router.HandleFunc(fmt.Sprintf("%s/todos/complete/{id}", funcPrefix), complete).Methods("PATCH")
	router.HandleFunc(fmt.Sprintf("%s/todos/{id}", funcPrefix), delete).Methods("DELETE")

	handler := cors.New(cors.Options{
		AllowedMethods: []string{"GET", "POST", "DELETE", "PATCH", "OPTIONS"},
	}).Handler(router)

	http.ListenAndServe(listenAddr, handler)
}

func healthz(w http.ResponseWriter, r *http.Request) {
	log.Info("API Health is OK")
	w.Header().Set("Content-Type", "application/json")
	io.WriteString(w, `{"alive": true}`)
}

func init() {
	log.SetFormatter(&log.TextFormatter{})
	log.SetReportCaller(true)
}

func create(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	t := CreateOrUpdateTodoItem{}

	err := json.NewDecoder(r.Body).Decode(&t)
	if err != nil {
		errMsg := fmt.Sprintf("{\"created: false, \"error\": \"%s\"}", err)
		io.WriteString(w, errMsg)
	}
	defer r.Body.Close()

	if t.Description == "" {
		errMsg := "{\"created: false, \"error\": \"Description must not be empty\"}"
		io.WriteString(w, errMsg)
	}

	log.WithFields(log.Fields{"description": t.Description}).Info("Add new TodoItem. Saving to database.")
	todo := &TodoItemEntity{Description: t.Description, Completed: false}
	db.Create(&todo)
	result := db.Last(&todo)
	json.NewEncoder(w).Encode(result.Value)
}

func update(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	vars := mux.Vars(r)
	id, _ := strconv.Atoi(vars["id"])

	var t CreateOrUpdateTodoItem

	decoder := json.NewDecoder(r.Body)
	if err := decoder.Decode(&t); err != nil {
		io.WriteString(w, `{"created: false, "error": "error marshalling JSON to todo item"}`)
	}
	defer r.Body.Close()

	if err := getItemById(id); !err {
		io.WriteString(w, `{"updated": "false", "error": "Record Not Found"}`)
	} else {
		log.WithFields(log.Fields{"Id": id}).Info("Updating TodoItem")
		todo := &TodoItemEntity{}
		db.First(&todo, id)
		todo.Description = t.Description
		db.Save(&todo)
		io.WriteString(w, `{"updated": true}`)
	}
}

func complete(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	vars := mux.Vars(r)
	id, _ := strconv.Atoi(vars["id"])

	if err := getItemById(id); !err {
		io.WriteString(w, `{"deleted": false, "error": "Record Not Found"}`)
	} else {
		todo := &TodoItemEntity{}
		db.First(&todo, id)
		todo.Completed = true
		db.Save(&todo)
		io.WriteString(w, `{"updated": true}`)
	}
}

func delete(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	vars := mux.Vars(r)
	id, _ := strconv.Atoi(vars["id"])

	if err := getItemById(id); !err {
		io.WriteString(w, `{"deleted": "false", "error": "Record Not Found"}`)
	} else {
		log.WithFields(log.Fields{"Id": id}).Info("Delete TodoItem")
		todo := &TodoItemEntity{}
		db.First(&todo, id)
		db.Delete(&todo)
		io.WriteString(w, `{"deleted": true}`)
	}
}

func get(w http.ResponseWriter, r *http.Request) {
	allTodoItems := getAll()
	log.Info("Get all TodoItems count: %d", allTodoItems)
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(allTodoItems)
}

func getCompleted(w http.ResponseWriter, r *http.Request) {
	log.Info("Get completed TodoItems")
	completedTodoItems := getByCompletionStatus(true)
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(completedTodoItems)
}

func getIncomplete(w http.ResponseWriter, r *http.Request) {
	log.Info("Get Incomplete TodoItems")
	incompleteTodoItems := getByCompletionStatus(false)
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(incompleteTodoItems)
}

func getAll() interface{} {
	var todos []TodoItemEntity
	TodoItems := db.Find(&todos).Value
	return TodoItems
}

func getByCompletionStatus(completed bool) interface{} {
	var todos []TodoItemEntity
	TodoItems := db.Where("completed = ?", completed).Find(&todos).Value
	return TodoItems
}

func getItemById(Id int) bool {
	todo := &TodoItemEntity{}
	result := db.First(&todo, Id)
	if result.Error != nil {
		log.Warn("Todo item not found in database")
		return false
	}
	return true
}
