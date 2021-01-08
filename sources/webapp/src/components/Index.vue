<template>
  <div class="index">
    <!-- Container -->
    <b-container class="bv-example-row">
        <h2 id="indexHeader">Synthetic Monitoring Service</h2>
        <div v-if="loading" class="loading">
            <h6>Loading...</h6>
            <img src="/static/images/spinner.gif" width="32" height="32"/>
        </div>
        <div v-else>
            <p>Graph</p>
        </div>
    </b-container>
  </div>
</template>

<script>
import { postFiles } from '@/api'

export default {
  name: 'Index',
  props: ['loading', 'data', 'labels'],
  data() {
    return {
      error: '',
      files: [],
      taskId: '',
      taskStatus: '',
      results: ''
    }
  },
  watch: {
    'taskId': function(value) {
        if (value != '') {
          /* Dispatch asynchronous action to Vuex */
          this.$store.dispatch('getStatus', {taskId: value})
            .catch(err => {
              /* Display error message */
              this.error = err.message
            })
        }
    }
  },
  methods: {
    onSubmit(evt) {
      evt.preventDefault()
      if (this.files) {
        postFiles(this.files)
          .then(response => {
            this.$refs['files-input'].reset()
            this.taskId = response.task_id
          })
          .catch(err => {
            /* Reset our form values */
            this.error = err.message
          })
        this.$refs['files-input'].reset()
      }
    },
    onReset(evt) {
      evt.preventDefault()
      this.$refs['files-input'].reset()
    }
  }
}
</script>

<style scoped>
h1, h2 {
  font-weight: normal;
}
ul {
  list-style-type: none;
  padding: 0;
}
li {
  display: inline-block;
  margin: 0 10px;
}
.container {
  max-width: 800px;
  margin:  0 auto;
}
.image {
  height: 160px;
}
.error {
  color: #e43f3f;
  font-weight: bold;
}
</style>
