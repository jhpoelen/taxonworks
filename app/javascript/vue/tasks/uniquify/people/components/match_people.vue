<template>
  <div>
    <autocomplete
      url="/people/autocomplete"
      min="2"
      label="label"
      placeholder="Search person"
      display="label"
      @getItem="addToList($event)"
      param="term"/>
    <p v-if="Object.keys(selectedPerson).length">{{ matchPeople.length }}  matches found</p>
    <div>
      <ul class="no_bullets">
        <li v-for="person in matchPeople">
          <label>
            <input
              name="match-people"
              type="radio"
              v-model="selected"
              :value="person.id"
              @click="selectMergePerson(person)">
            {{ person.cached }}
          </label>
        </li>
      </ul>
    </div>
  </div>
</template>
<script>
// this is a list for selecting one person from potential matchees
// only one person can be selected
import Autocomplete from '../../../../components/autocomplete.vue'

export default {
  components: {
    Autocomplete
  },
  props: {
    value: {
      type: Object,
      required: true
    },
    selectedPerson: {
      type: Object,
      required: true
    }
  },
  watch: {
    selectedPerson(newVal) {
      this.getMatchPeople(newVal);
    }
  },
  data() {
    return {
      matchPeople: [],
      mergePerson: {},
      selected: {} // gets populated by the v-model to the value attribute of the radio button input
    };
  },
  methods: {
    removeFromList(personId) {
      let index = this.matchPeople.findIndex(item => {
        return item.id == personId;
      });

      if (index > -1) this.matchPeople.splice(index, 1);
      this.mergePerson = {};
    },
    addToList(person) {
      person['cached'] = person.label
      this.matchPeople.push(person)
      this.selectMergePerson(person)
      this.selected = person
    },
    selectMergePerson(person) {
      this.$http
        .get("/people/" + person.id.toString() + ".json")
        .then(response => {
          this.mergePerson = response.body;
          this.$emit("input", this.mergePerson);
        });
    },
    getMatchPeople(person) {
      this.mergePerson = {};
      this.selected = {};
      if (person.last_name == undefined && person.last_name == undefined) {
        this.matchPeople = []; // new search
        this.mergePerson = {};
        this.selected = {};
        return false;
      }
    //   let params = {   // fudge up new search for match params to give some likely hits
    //   id: person.id
    //   last_name: person.last_name.substr(0,3),
    //   first_name: '', //person.first_name[0] + '*',
    //   roles: []
    // };
      this.$http.get("/people/" + person.id.toString() + "/similar").then(response => {
        this.matchPeople = response.body;
        this.removeFromList(person.id);
        this.$emit("matchPeople", this.matchPeople)   // notify app's watcher
      });
    }
  }
};
</script>

